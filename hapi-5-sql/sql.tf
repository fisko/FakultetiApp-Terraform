# sql.tf — Azure SQL Server + bazë të dhënash FALAS (free offer), dhe sekreti me connection string.

# Fjalëkalimi gjenerohet nga Terraform (nuk e shkruajmë në kod).
# KUJDES: ruhet në state, prandaj state nuk duhet publikuar kurrë (shih docs/06-state-dhe-sekretet.md)
resource "random_password" "sql" {
  length      = 24
  special     = false # pa simbole, që connection string të mos prishet
  min_lower   = 2
  min_upper   = 2
  min_numeric = 2
}

# SQL Server = "kontejneri" logjik; bazat e të dhënave jetojnë brenda tij
resource "azurerm_mssql_server" "sql" {
  name                         = "sql-tf-${var.emri}-${local.prapashtesa}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0" # kështu quhet versioni aktual i Azure SQL
  administrator_login          = "dbadmin"
  administrator_login_password = random_password.sql.result
  minimum_tls_version          = "1.2" # refuzon lidhjet e vjetra e të pasigurta
  tags                         = local.tags
}

# Offerta falas e Azure SQL (General Purpose serverless, 100,000 vCore-sekonda/muaj, 32 GB).
# Provider-i azurerm nuk e ka ende opsionin "useFreeLimit", prandaj përdorim azapi,
# që flet drejtpërdrejt me API-n e Azure (Resource Manager) me çdo veti që ofron.
resource "azapi_resource" "db" {
  type      = "Microsoft.Sql/servers/databases@2023-08-01-preview" # lloji + versioni i API-t
  name      = "db-${var.emri}"
  parent_id = azurerm_mssql_server.sql.id # baza është "fëmijë" i serverit
  location  = azurerm_resource_group.rg.location
  tags      = local.tags

  # body = JSON që dërgohet te Azure (këtu shkruhet si objekt HCL)
  body = {
    sku = {
      name     = "GP_S_Gen5_2" # General Purpose, Serverless, Gen5, 2 vCore maksimum
      tier     = "GeneralPurpose"
      family   = "Gen5"
      capacity = 2
    }
    properties = {
      autoPauseDelay              = 60 # pauzohet pas 60 min pa përdorim (kursen kuotën)
      minCapacity                 = 0.5
      maxSizeBytes                = 34359738368 # 32 GB
      useFreeLimit                = true        # ky aktivizon offertën FALAS
      freeLimitExhaustionBehavior = "AutoPause" # kur mbaron kuota falas, baza pauzohet (pa faturë)
    }
  }
}

# Firewall: lejon shërbimet e Azure (App Service) të lidhen.
# Adresa speciale 0.0.0.0 - 0.0.0.0 do të thotë "çdo shërbim i Azure", jo çdo IP.
resource "azurerm_mssql_firewall_rule" "azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# VETËM PËR MËSIM: lejon çdo IP (që të lidheni nga kompjuteri juaj). Në prodhim NUK bëhet.
resource "azurerm_mssql_firewall_rule" "te_gjitha" {
  name             = "AllowAll-VetemPerMesim"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

# Connection string ruhet në Key Vault; aplikacioni e lexon përmes referencës te app_settings (main.tf)
resource "azurerm_key_vault_secret" "sql" {
  name         = "SqlConnection"
  value        = "Server=tcp:${azurerm_mssql_server.sql.fully_qualified_domain_name},1433;Database=${azapi_resource.db.name};User ID=dbadmin;Password=${random_password.sql.result};Encrypt=True;TrustServerCertificate=False;Connection Timeout=60;"
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [time_sleep.pritje_rolet]
}
