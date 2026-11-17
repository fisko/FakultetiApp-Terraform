# mbrojtja.tf — mbrojtje nga fshirja aksidentale dhe nga kostot (opsionale).

# 1) LOCK: Azure refuzon fshirjen e grupit ose burimeve brenda tij derisa locku të hiqet.
#    Terraform e menaxhon lock-un. Që "terraform destroy" ta heqë PARA fshirjes së burimeve të tjera,
#    lock-un e bëjmë të varur nga ato (depends_on): Terraform i fshin në radhë të kundërt, pra lock-un e para.
#    Aktivizohet me:  mbro_nga_fshirja = true
resource "azurerm_management_lock" "rg" {
  count      = var.mbro_nga_fshirja ? 1 : 0
  name       = "mos-fshij"
  scope      = azurerm_resource_group.rg.id
  lock_level = "CanNotDelete"
  notes      = "Vendosur nga Terraform; mbron nga fshirja aksidentale"

  depends_on = [
    azurerm_storage_container.dokumentet,
    module.webapp,
    azurerm_key_vault_secret.sql,
    azurerm_key_vault_secret.storage,
    azapi_resource.db,
    azurerm_mssql_firewall_rule.azure,
    azurerm_mssql_firewall_rule.te_gjitha,
    azurerm_application_insights.ai,
    azurerm_monitor_metric_alert.http5xx,
    azurerm_consumption_budget_resource_group.buxheti,
  ]
}

# 2) lifecycle { prevent_destroy = true } është mbrojtja brenda vetë Terraform: çdo plan që fshin
#    burimin dështon me gabim. Shembull (provojeni si ushtrim te Key Vault, te keyvault.tf):
#
#      resource "azurerm_key_vault" "kv" {
#        ...
#        lifecycle {
#          prevent_destroy = true
#        }
#      }
#
#    Kujdes: nuk mund të vihet me variabël, dhe pastaj "terraform destroy" nuk punon derisa ta hiqni.

# 3) BUXHETI: njoftim me email kur shpenzimi i grupit afrohet te kufiri.
#    Aktivizohet vetëm kur jepet alert_email. Kufiri është në USD.
resource "azurerm_consumption_budget_resource_group" "buxheti" {
  count             = var.alert_email == "" ? 0 : 1
  name              = "buxhet-${var.emri}"
  resource_group_id = azurerm_resource_group.rg.id

  amount     = var.buxheti_usd
  time_grain = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    contact_emails = [var.alert_email]
  }

  lifecycle {
    ignore_changes = [time_period] # timestamp() ndryshon çdo ditë; nuk duam plan të ri për këtë
  }
}
