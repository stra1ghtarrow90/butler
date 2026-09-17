output "subscription_id" {
  description = "Subscription used by this bootstrap."
  value       = var.subscription_id
}

output "state_resource_group" {
  value = azurerm_resource_group.state.name
}

output "storage_account_name" {
  value = azurerm_storage_account.state.name
}

output "backend_configuration" {
  description = "Non-secret backend settings for later roots. Initialize each root separately."
  value = {
    for environment in local.state_containers : environment => {
      resource_group_name  = azurerm_resource_group.state.name
      storage_account_name = azurerm_storage_account.state.name
      container_name       = azurerm_storage_container.state[environment].name
      key                  = "terraform.tfstate"
      subscription_id      = var.subscription_id
      tenant_id            = var.tenant_id
      use_azuread_auth     = true
      use_cli              = true
    }
  }
}
