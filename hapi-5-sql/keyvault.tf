# keyvault.tf — Key Vault, rolet (RBAC) dhe sekretet.
# Ideja: fjalëkalimet dhe connection strings nuk shkruhen në kod; ruhen në Key Vault,
# dhe aplikacioni i lexon me Managed Identity.

# data = LEXON informacion që ekziston tashmë (nuk krijon asgjë).
# Këtu: kush jam unë (tenant dhe object id i përdoruesit ose service principal-it që po ekzekuton Terraform)
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                       = "kv-${var.emri}-${local.prapashtesa}" # unik në botë, 3-24 karaktere
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true  # lejet jepen me role (RBAC), jo me "access policies" të vjetra
  soft_delete_retention_days = 7     # pas fshirjes, Key Vault mund të rikthehet 7 ditë
  purge_protection_enabled   = false # për mësim; në prodhim vendoset true
  tags                       = local.tags
}

# Ju (ai që ekzekuton Terraform) merrni të drejtë të SHKRUANI sekrete
resource "azurerm_role_assignment" "ti_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Aplikacioni (me Managed Identity) merr të drejtë VETËM të LEXOJË sekrete (parimi i privilegjit minimal)
resource "azurerm_role_assignment" "app_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id # [0] = elementi i parë i listës
}

# Rolet marrin disa sekonda të përhapen në Azure; pa pritje krijimi i sekretit mund të dështojë me 403.
# time_sleep nuk krijon asgjë në Azure, vetëm pret.
resource "time_sleep" "pritje_rolet" {
  depends_on      = [azurerm_role_assignment.ti_officer, azurerm_role_assignment.app_user]
  create_duration = "60s"
}

resource "azurerm_key_vault_secret" "storage" {
  name         = "StorageConnection"
  value        = azurerm_storage_account.st.primary_connection_string # vlera merret nga Storage pa e parë ne
  key_vault_id = azurerm_key_vault.kv.id

  # depends_on = varësi e shprehur manualisht (Terraform nuk e di vetë që duhet të presë rolet)
  depends_on = [time_sleep.pritje_rolet]
}
