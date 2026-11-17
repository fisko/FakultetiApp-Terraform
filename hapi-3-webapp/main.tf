# main.tf — Hapi 3: shtojmë App Service Plan (F1 falas) dhe Web App me Managed Identity.

# random_string: gjenerohet NJË herë dhe ruhet në state; emrat në Azure duhet të jenë unikë në botë.
resource "random_string" "suffix" {
  length  = 5
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# locals: vlera të llogaritura që i ripërdorim; tags vihen në çdo burim
locals {
  prapashtesa = random_string.suffix.result
  tags = {
    projekti = "FakultetiApp"
    studenti = var.emri
    krijuar  = "terraform"
  }
}

# Resource Group = "folderi" që mban burimet
resource "azurerm_resource_group" "rg" {
  name     = "rg-tf-${var.emri}"
  location = var.location
  tags     = local.tags
}

# Storage account për blobs (LRS = kopja më e lirë)
resource "azurerm_storage_account" "st" {
  name                     = "st${var.emri}${local.prapashtesa}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}

# Container privat për dokumentet
resource "azurerm_storage_container" "dokumentet" {
  name                  = "dokumentet-${var.emri}"
  storage_account_id    = azurerm_storage_account.st.id
  container_access_type = "private"
}

# App Service Plan = "kompjuteri" ku punon aplikacioni. Linux + F1 (falas)
resource "azurerm_service_plan" "plan" {
  name                = "plan-tf-${var.emri}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = var.plan_sku
  tags                = local.tags
}

# Web App = aplikacioni vetë (.NET 10)
resource "azurerm_linux_web_app" "app" {
  name                = "app-tf-${var.emri}-${local.prapashtesa}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true # HTTP ridrejtohet te HTTPS
  tags                = local.tags

  # Managed Identity: Azure i jep aplikacionit një identitet; me të lexon sekrete pa fjalëkalim
  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = false # F1 nuk e mbështet "always on"

    application_stack {
      dotnet_version = "10.0"
    }
  }

  # app_settings bëhen variabla ambienti; "__" në .NET do të thotë ":"
  app_settings = {
    "Blob__Container" = azurerm_storage_container.dokumentet.name
  }
}
