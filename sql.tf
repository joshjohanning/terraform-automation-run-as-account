resource "random_string" "sqlpassword" {
  length  = 16
  special = false
}

resource "azurerm_mssql_server" "sqlusnc" {
  name                         = "usnca-cdw-edw-sql-${terraform.workspace}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = "North Central US"
  version                      = "12.0"
  administrator_login          = "cdwadmin"
  administrator_login_password = random_string.sqlpassword.result
  minimum_tls_version          = "1.2"
  tags = {
    environment = terraform.workspace
  }

  identity {
    type         = "SystemAssigned" 
  }

  azuread_administrator {
    login_username = "Test Group"
    object_id      = data.azuread_group.sqladmin.id
    tenant_id      = data.azurerm_subscription.primary.tenant_id
  }
}

resource "azurerm_sql_firewall_rule" "rules" {
  count               = length(var.sql_firewall_rules)
  name                = element(keys(var.sql_firewall_rules), count.index)
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mssql_server.sqlusnc.name
  start_ip_address    = var.sql_firewall_rules[element(keys(var.sql_firewall_rules), count.index)]["ip"]
  end_ip_address      = var.sql_firewall_rules[element(keys(var.sql_firewall_rules), count.index)]["ip"]
}

resource "azurerm_mssql_database" "sqlusnc" {
  name           = "usnca-cdw-edw-sql-db-primary-${terraform.workspace}"
  server_id      = azurerm_mssql_server.sqlusnc.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 500
  read_scale     = false
  sku_name       = "GP_Gen5_2"
  zone_redundant = false
}

resource "azurerm_mssql_server" "sqlussc" {
  name                         = "ussca-cdw-edw-sql-${terraform.workspace}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = "South Central US"
  version                      = "12.0"
  administrator_login          = "cdwadmin"
  administrator_login_password = random_string.sqlpassword.result
  minimum_tls_version          = "1.2"
  tags = {
    environment = terraform.workspace
  }

  identity {
    type         = "SystemAssigned" 
  }
}

resource "azurerm_mssql_database" "sqlussc" {
  name                        = "ussca-cdw-edw-sql-db-secondary-${terraform.workspace}"
  server_id                   = azurerm_mssql_server.sqlussc.id
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  license_type                = "LicenseIncluded"
  max_size_gb                 = 500
  read_scale                  = false
  sku_name                    = "GP_Gen5_2"
  zone_redundant              = false
  create_mode                 = "Secondary"
  creation_source_database_id = azurerm_mssql_database.sqlusnc.id
}
