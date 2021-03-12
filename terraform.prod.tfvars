sql_database_primary_sku   = "GP_Gen5_8"
sql_database_secondary_sku = "GP_Gen5_2"

azuread_administrator_login_username = "IT Enterprise Analytics AZ"
azuread_administrator_object_id      = "0fc2980e-659b-42a2-8b8e-a72ffb5ca67c"

# Defaults to group: MKTDataScience_Group_ADL
container_reader_assignment_group_id = "4f58cfa6-0289-4a4c-b25d-b924a1817b70"

key_vault_access_policy_azure_pipelines_spn = "b9ba6ff8-bf05-4883-a14b-b8bb8a422add"

# dev data factory
key_vault_access_policy_data_factory_spn = "fcbbba11-9aeb-4bc1-a595-a70838fdd447"

# these rules only apply to prod
sql_firewall_rules = {
  # 0.0.0.0 is the allow all azure services - see: https://docs.microsoft.com/en-us/rest/api/sql/firewallrules/createorupdate
  "AllowAllWindowsAzureIps" = {
    "ip" = "0.0.0.0"
  }
}
