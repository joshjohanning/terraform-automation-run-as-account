resource "azurerm_automation_account" "account" {
  name                = "JOSHACCOUNT-${upper(terraform.workspace)}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku_name = "Basic"

}

data "local_file" "sqlautoscale" {
  filename = "${path.module}/azure-automation-runbooks/AzureSQLDatabaseScheduledAutoScaling.ps1"
}

resource "azurerm_automation_runbook" "sqlautoscale" {
  name                    = "AzureSQLDatabaseScheduledAutoScaling"
  resource_group_name     = azurerm_resource_group.rg.name
  location                = azurerm_resource_group.rg.location
  automation_account_name = azurerm_automation_account.account.name
  log_verbose             = "false"
  log_progress            = "false"
  description             = "Vertically scale an Azure SQL Database up or down according to a schedule using Azure Automation."
  runbook_type            = "PowerShell"

  content = data.local_file.sqlautoscale.content
}

resource "azurerm_automation_schedule" "databasescaling" {
  name                    = "Database scaling"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.account.name
  frequency               = "Hour"
  interval                = 1
  start_time              = "${local.update_date}T${local.update_time}:00-06:00"
  timezone                = "America/Chicago"
}

resource "azurerm_automation_job_schedule" "sqlautoscale" {
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.account.name
  schedule_name           = azurerm_automation_schedule.databasescaling.name
  runbook_name            = azurerm_automation_runbook.sqlautoscale.name

  parameters = {
    resourcegroupname       = "\"${azurerm_resource_group.rg.name}\""
    databasename            = "\"dbname\""
    servername              = "\"servername\""
    defaultedition          = "\"None\""
    defaulttier             = "\"GP_Gen5_2\""
    scalingschedule         = "\"[{WeekDays:[0,6], StartTime:\\\"2021:02:24:07:59:59\\\", StopTime:\\\"2021:02:24:16:59:59\\\", Edition: \\\"None\\\", Tier: \\\"GP_Gen5_2\\\"}, {WeekDays:[1,2,3,4,5], StartTime:\\\"07:59:59\\\", StopTime:\\\"16:59:59\\\", Edition: \\\"None\\\", Tier: \\\"GP_Gen5_16\\\"}]\""
    scalingscheduletimezone = "\"Central Standard Time\""
  }
}

resource "time_offset" "end_date" {
  offset_hours = 24 * 365 * 25
}

resource "random_string" "random" {
  length  = 16
  special = false
}

resource "azuread_application" "runasaccount" {
  display_name = format("%s_%s", azurerm_automation_account.account.name, random_string.random.result)
}

resource "azuread_application_certificate" "certificate" {
  application_object_id = azuread_application.runasaccount.id
  type                  = "AsymmetricX509Cert"
  value                 = data.azurerm_key_vault_certificate_data.certificate.pem
  end_date              = time_offset.end_date.rfc3339
}

resource "azuread_service_principal" "runasaccount" {
  application_id = azuread_application.runasaccount.application_id

  depends_on = [
    azuread_application_certificate.certificate,
  ]
}

resource "azuread_service_principal_certificate" "certificate" {
  service_principal_id = azuread_service_principal.runasaccount.id
  type                 = "AsymmetricX509Cert"
  value                = data.azurerm_key_vault_certificate_data.certificate.pem
  end_date             = time_offset.end_date.rfc3339
}

resource "azurerm_role_assignment" "runasaccount" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.runasaccount.object_id
}

resource "azurerm_automation_certificate" "certificate" {
  name                    = "AzureRunAsCertificate"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.account.name
  base64                  = data.azurerm_key_vault_secret.certificate.value
}

resource "azurerm_automation_connection_service_principal" "runasaccount" {
  name                    = "AzureRunAsConnection"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.account.name
  application_id          = azuread_service_principal.runasaccount.application_id
  tenant_id               = data.azurerm_subscription.primary.tenant_id
  subscription_id         = data.azurerm_subscription.primary.subscription_id
  certificate_thumbprint  = azurerm_automation_certificate.certificate.thumbprint
}

resource "azurerm_key_vault_certificate" "certificate" {
  name         = "automation-account-cert-${upper(terraform.workspace)}"
  key_vault_id = azurerm_key_vault.secrets_keyvault.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {

      key_usage          = []
      subject            = "OU=JOSH, O=JOSH, L=Madison, S=Wisconsin, C=US"
      validity_in_months = 329
    }
  }
}

# These next 2 resources:
## * Setting up runbook job schedule - sets a static hour (01:00) and sets up the schedule for the next day starting at that hour
## * This is needed used to ensure that our runbook runs at the top of the hour, statically, and so terraform doesn't re-create the schedule during every run
locals {
  # update_time = formatdate("hh",timeadd(timestamp(), "-5h"))
  update_time = "01:00"
  update_date = substr(time_offset.schedule_start.rfc3339, 0, 10)
}

//== Store 1 day in the future, only update if [local.update_time] is altered ==//
resource "time_offset" "schedule_start" {
  offset_days = 1
  triggers = {
    update_time = local.update_time
  }
}
