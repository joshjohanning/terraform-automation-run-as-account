provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "AUTOMATION-ACCOUNT-${upper(terraform.workspace)}-RG"
  location = "North Central US"
  tags = {
    environment = terraform.workspace
  }
}