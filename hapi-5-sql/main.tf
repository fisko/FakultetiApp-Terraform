# main.tf — grupi, storage, plani dhe web app (ndryshon vetëm app_settings).
# Key Vault është te keyvault.tf; SQL është te sql.tf

resource "random_string" "suffix" {
  length  = 5
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  prapashtesa = random_string.suffix.result
  tags = {
    projekti = "FakultetiApp"
    studenti = var.emri
    krijuar  = "terraform"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-tf-${var.emri}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "st" {
  name                     = "st${var.emri}${local.prapashtesa}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}

resource "azurerm_storage_container" "dokumentet" {
  name                  = "dokumentet-${var.emri}"
  storage_account_id    = azurerm_storage_account.st.id
  container_access_type = "private"
}

resource "azurerm_service_plan" "plan" {
  name                = "plan-tf-${var.emri}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = var.plan_sku
  tags                = local.tags
}

resource "azurerm_linux_web_app" "app" {
  name                = "app-tf-${var.emri}-${local.prapashtesa}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true
  tags                = local.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = false

    application_stack {
      dotnet_version = "10.0"
    }
  }

  app_settings = {
    "Blob__Container" = azurerm_storage_container.dokumentet.name

    # REFERENCË te Key Vault: në app ruhet vetëm "pointer"; vlera e vërtetë mbetet në Key Vault
    "ConnectionStrings__Storage" = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.kv.name};SecretName=StorageConnection)"
    "ConnectionStrings__Sql"     = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.kv.name};SecretName=SqlConnection)"
  }
}
