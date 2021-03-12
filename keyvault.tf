resource "azurerm_key_vault" "secrets_keyvault" {
  name                = "joshautodwkeyvault-${terraform.workspace}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tenant_id = data.azurerm_subscription.primary.tenant_id

  sku_name                        = "standard"
  enabled_for_deployment          = true
  enabled_for_template_deployment = false
  enabled_for_disk_encryption     = false
}

resource "azurerm_key_vault_access_policy" "azure_pipelines" {
  key_vault_id = azurerm_key_vault.secrets_keyvault.id

  tenant_id = data.azurerm_subscription.primary.tenant_id
  object_id = var.key_vault_access_policy_azure_pipelines_spn

  secret_permissions = [
    "Get",
    "List"
  ]

  certificate_permissions = [
    "create",
    "delete",
    "get",
    "list",
    "update",
    "recover"
  ]
}