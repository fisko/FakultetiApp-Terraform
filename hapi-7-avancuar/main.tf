# main.tf — burimet kryesore: grupi, Storage, App Service Plan dhe Web App.
# Key Vault është te keyvault.tf; SQL është te sql.tf.
# Terraform i lexon të gjitha skedarët .tf në këtë folder si një e vetme; emrat e skedarëve janë vetëm për rregull.
#
# Sintaksa e përgjithshme:  resource "<LLOJI>" "<EMRI_LOKAL>" { ... }
#   LLOJI      = çfarë krijohet në Azure (p.sh. azurerm_storage_account)
#   EMRI_LOKAL = si e quajmë në kod; përdoret për t'iu referuar (azurerm_resource_group.rg.name)

# ---------------------------------------------------------------------------
# 1) Prapashtesa e rastësishme
# ---------------------------------------------------------------------------
# random_string gjenerohet NJË herë dhe ruhet në state, prandaj mbetet e njëjtë në çdo "apply".
# Na duhet sepse emrat e Storage, Key Vault, SQL dhe Web App duhet të jenë unikë në gjithë botën.
resource "random_string" "suffix" {
  length  = 5
  lower   = true
  upper   = false # Storage account pranon vetëm shkronja të vogla
  numeric = true
  special = false
}

# ---------------------------------------------------------------------------
# 2) locals = vlera të llogaritura që i ripërdorim (si variabla të brendshme)
# ---------------------------------------------------------------------------
locals {
  prapashtesa = random_string.suffix.result

  # Emri i plotë = emri + mjedisi (p.sh. "ardian" + "dev" = "ardiandev"). Pa mjedis mbetet vetëm emri.
  emri_plote = "${var.emri}${var.mjedisi}"

  # Etiketat (tags) vihen në çdo burim; ndihmojnë të dimë kush e ka krijuar dhe pse
  tags = merge(
    {
      projekti = "FakultetiApp"
      studenti = var.emri
      krijuar  = "terraform"
    },
    var.mjedisi == "" ? {} : { mjedisi = var.mjedisi },
    # skadon = data pas së cilës scripts/pastro-skaduar.ps1 e fshin grupin automatikisht
    var.skadon == "" ? {} : { skadon = var.skadon },
  )
}

# ---------------------------------------------------------------------------
# 3) Resource Group = "folderi" që mban të gjitha burimet
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = "rg-tf-${local.emri_plote}" # emri në Azure; ${...} fut vlerën e variablës
  location = var.location
  tags     = local.tags
}

# ---------------------------------------------------------------------------
# 4) Storage account (për blobs) dhe container-i i dokumenteve
# ---------------------------------------------------------------------------
# Kur shkruajmë azurerm_resource_group.rg.name, Terraform kupton vetë që grupi duhet krijuar
# PARA storage-it. Kjo quhet varësi e nënkuptuar (implicit dependency).
resource "azurerm_storage_account" "st" {
  name                            = "st${local.emri_plote}${local.prapashtesa}" # vetëm shkronja të vogla dhe numra, max 24
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"    # kopja më e lirë (3 kopje në një datacenter)
  min_tls_version                 = "TLS1_2" # hardening: refuzon TLS të vjetër
  allow_nested_items_to_be_public = false    # hardening: asnjë blob nuk mund të bëhet publik
  tags                            = local.tags
}

resource "azurerm_storage_container" "dokumentet" {
  name                  = "dokumentet-${local.emri_plote}"
  storage_account_id    = azurerm_storage_account.st.id
  container_access_type = "private" # askush nuk i hap skedarët pa autorizim
}

# ---------------------------------------------------------------------------
# 5) Plan + Web App përmes MODULIT (folderi modules/webapp)
# ---------------------------------------------------------------------------
# Njësoj si një funksion: i japim hyrjet, na kthen daljet. Kodi i planit dhe i app është te modules/webapp.
module "webapp" {
  source = "./modules/webapp"

  emri                = local.emri_plote
  prapashtesa         = local.prapashtesa
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  plan_sku            = var.plan_sku
  tags                = local.tags

  # "__" në .NET do të thotë ":" (ConnectionStrings__Sql lexohet si ConnectionStrings:Sql)
  app_settings = {
    "Blob__Container" = azurerm_storage_container.dokumentet.name

    # REFERENCË te Key Vault: në app ruhet vetëm "pointer"; vlera e vërtetë mbetet në Key Vault
    "ConnectionStrings__Storage" = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.kv.name};SecretName=StorageConnection)"
    "ConnectionStrings__Sql"     = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.kv.name};SecretName=SqlConnection)"

    # Monitorimi (shih monitor.tf)
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.ai.connection_string
  }
}

# Nëse e keni aplikuar hapi-6, këto blloqe "moved" i tregojnë Terraform-it që burimet thjesht
# ndryshuan vend (në modul); pa to do t'i fshinte dhe t'i krijonte përsëri.
moved {
  from = azurerm_service_plan.plan
  to   = module.webapp.azurerm_service_plan.plan
}

moved {
  from = azurerm_linux_web_app.app
  to   = module.webapp.azurerm_linux_web_app.app
}
