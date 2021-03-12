# azure subscription info
data "azurerm_subscription" "primary" {}

# reads in key vault for sql server admin password
data "azurerm_key_vault" "sqlkv" {
  name                = azurerm_key_vault.secrets_keyvault.name
  resource_group_name = azurerm_resource_group.rg.name
}

# azure automation run as account - so you can export the pfx with the private key
data "azurerm_key_vault_secret" "certificate" {
  name         = azurerm_key_vault_certificate.certificate.name
  key_vault_id = azurerm_key_vault.secrets_keyvault.id
}

# azure automation run as account - so you can export the pem
data "azurerm_key_vault_certificate_data" "certificate" {
  name         = azurerm_key_vault_certificate.certificate.name
  key_vault_id = azurerm_key_vault.secrets_keyvault.id
}
