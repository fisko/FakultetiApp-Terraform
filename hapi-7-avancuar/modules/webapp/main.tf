# Moduli "webapp" = App Service Plan + Web App (me Managed Identity) të paketuar si njësi e ripërdorshme.
# Një modul është thjesht një folder me skedarë .tf. Ai ka hyrjet (variables.tf) dhe daljet (outputs.tf) e veta.

resource "azurerm_service_plan" "plan" {
  name                = "plan-tf-${var.emri}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.plan_sku
  tags                = var.tags
}

resource "azurerm_linux_web_app" "app" {
  name                = "app-tf-${var.emri}-${var.prapashtesa}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on     = false      # F1 nuk e mbështet "always on"
    ftps_state    = "Disabled" # hardening: pa deploy me FTP
    http2_enabled = true

    application_stack {
      dotnet_version = var.dotnet_version
    }
  }

  # Moduli nuk di asgjë për Key Vault apo SQL; cilësimet vijnë nga jashtë
  app_settings = var.app_settings
}
