# monitor.tf — Application Insights (monitorim i aplikacionit) + Log Analytics Workspace.
# Application Insights i ri ruan të dhënat në një Log Analytics Workspace.
# Kosto: 5 GB të dhëna në muaj janë falas; për mësim mbetemi shumë poshtë kësaj.

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-tf-${var.emri}-${local.prapashtesa}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30  # ruajtja e logjeve (30 ditë = pa pagesë shtesë)
  daily_quota_gb      = 0.1 # kufi i sigurisë: max 0.1 GB në ditë, që të mos kalojmë kuotën falas
  tags                = local.tags
}

resource "azurerm_application_insights" "ai" {
  name                = "ai-tf-${var.emri}-${local.prapashtesa}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
  tags                = local.tags
}

# Alarm i thjeshtë: nëse ka gabime serveri (HTTP 5xx), dërgo email. Vetëm kur jepet alert_email.
resource "azurerm_monitor_action_group" "email" {
  count               = var.alert_email == "" ? 0 : 1
  name                = "ag-tf-${var.emri}"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "tf${substr(var.emri, 0, 8)}"

  email_receiver {
    name          = "student"
    email_address = var.alert_email
  }
}

resource "azurerm_monitor_metric_alert" "http5xx" {
  count               = var.alert_email == "" ? 0 : 1
  name                = "alarm-5xx-${var.emri}"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [module.webapp.id]
  description         = "Aplikacioni po kthen gabime serveri (5xx)"
  frequency           = "PT5M"
  window_size         = "PT15M"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = azurerm_monitor_action_group.email[0].id
  }

  tags = local.tags
}
