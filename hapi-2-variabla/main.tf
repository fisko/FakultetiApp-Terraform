# main.tf — Hapi 2: variabla, locals, random dhe një Storage account me container.

# random_string: gjenerohet NJË herë dhe ruhet në state; mbetet i njëjtë në çdo "apply" tjetër.
# Na duhet sepse emrat e Storage/Key Vault/Web App duhet të jenë unikë në gjithë botën.
resource "random_string" "suffix" {
  length  = 5
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# locals: vlera të llogaritura që i ripërdorim (si variabla të brendshme)
locals {
  prapashtesa = random_string.suffix.result

  # Etiketa (tags) që vihen në çdo burim; ndihmojnë të gjejmë kush e ka krijuar
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

# Storage account (për blobs). Referojmë grupin me azurerm_resource_group.rg.name:
# kështu Terraform e di që grupi duhet krijuar PARA storage-it (varësi automatike).
resource "azurerm_storage_account" "st" {
  name                     = "st${var.emri}${local.prapashtesa}" # vetëm shkronja të vogla dhe numra, max 24
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # kopja më e lirë
  tags                     = local.tags
}

# Container-i ku ruhen dokumentet e aplikacionit
resource "azurerm_storage_container" "dokumentet" {
  name                  = "dokumentet-${var.emri}"
  storage_account_id    = azurerm_storage_account.st.id
  container_access_type = "private"
}
