variable "azuread_administrator_login_username" {
  description = "Azure AD Administrator login username"
  default     = ""
}

variable "azuread_administrator_object_id" {
  description = "Azure AD Object ID"
  default     = ""
}

variable "key_vault_access_policy_azure_pipelines_spn" {
  description = "objects to add to key vault access policy"
  default     = ""
}

variable "key_vault_access_policy_data_factory_spn" {
  description = "objects to add to key vault access policy"
  default     = "" # dev
}

# update the environment .tfvars file to populate sql firewall rules (ie: terraform.dev.tfvars)
variable "sql_firewall_rules" {
  default = {
    # 0.0.0.0 is the allow all azure services - see: https://docs.microsoft.com/en-us/rest/api/sql/firewallrules/createorupdate
    "AllowAllWindowsAzureIps" = {
      "ip" = "0.0.0.0"
    }
  }
}