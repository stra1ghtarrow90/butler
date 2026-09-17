locals {
  subscription_scope = "/subscriptions/${var.subscription_id}"
  state_containers   = toset(["platform", "devops", "candidate", "release"])
  tags = {
    project     = var.name_prefix
    environment = "lab"
    managed_by  = "terraform"
    owner       = var.operator_object_id
    expires_on  = var.expires_on
  }
}

# Storage is currently unregistered in this subscription. Consumption is already
# registered, so leave that pre-existing registration outside this state.
resource "azurerm_resource_provider_registration" "storage" {
  name = "Microsoft.Storage"
}

resource "azurerm_resource_group" "state" {
  name     = "rg-${var.name_prefix}-tfstate"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "state" {
  name                              = "st${var.name_prefix}${substr(sha256(var.subscription_id), 0, 10)}"
  resource_group_name               = azurerm_resource_group.state.name
  location                          = azurerm_resource_group.state.location
  account_kind                      = "StorageV2"
  account_tier                      = "Standard"
  account_replication_type          = "LRS"
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  shared_access_key_enabled         = false
  allow_nested_items_to_be_public   = false
  default_to_oauth_authentication   = true
  public_network_access             = "Enabled"
  cross_tenant_replication_enabled  = false
  infrastructure_encryption_enabled = true
  local_user_enabled                = false
  tags                              = local.tags

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  depends_on = [azurerm_resource_provider_registration.storage]
}

resource "azurerm_role_assignment" "operator_state" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.operator_object_id
  principal_type       = "User"
}

resource "azurerm_storage_container" "state" {
  for_each = local.state_containers

  name                  = each.value
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"

  # Preserve the operator's data access until all containers are removed.
  depends_on = [azurerm_role_assignment.operator_state]
}

resource "azurerm_consumption_budget_subscription" "lab" {
  name            = "${var.name_prefix}-lab-monthly"
  subscription_id = local.subscription_scope
  amount          = var.monthly_budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = "${var.budget_start_date}T00:00:00Z"
  }

  dynamic "notification" {
    for_each = toset([50, 80, 100])

    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThanOrEqualTo"
      threshold_type = "Actual"
      contact_roles  = ["Owner"]
      contact_emails = var.budget_contact_emails
    }
  }
}
