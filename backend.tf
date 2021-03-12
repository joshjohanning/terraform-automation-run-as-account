terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-automation-account-state"
    storage_account_name = "tfautomationaccount"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}