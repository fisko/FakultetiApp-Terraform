# outputs.tf — vlerat që Terraform na i shfaq në fund të "apply" (ose me "terraform output").

output "resource_group" {
  description = "Emri i grupit të krijuar"
  value       = azurerm_resource_group.rg.name
}

output "storage_account" {
  description = "Emri i Storage account"
  value       = azurerm_storage_account.st.name
}

output "key_vault" {
  description = "Emri i Key Vault"
  value       = azurerm_key_vault.kv.name
}

output "sql_server" {
  description = "Adresa (FQDN) e SQL Server"
  value       = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "app_name" {
  description = "Emri i Web App (futeni te GitHub Secret APP_NAME)"
  value       = azurerm_linux_web_app.app.name
}

output "app_url" {
  description = "Adresa e aplikacionit"
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
}
