terraform {
  required_version = ">= 1.13.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 5.5.0"
    }
  }

  # Keep bootstrap state local so it can destroy the remote backend last.
  backend "local" {}
}

provider "azurerm" {
  subscription_id                 = var.subscription_id
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
  storage_use_azuread             = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}
