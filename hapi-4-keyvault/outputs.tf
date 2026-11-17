output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "storage_account" {
  value = azurerm_storage_account.st.name
}

output "key_vault" {
  value = azurerm_key_vault.kv.name
}

output "app_name" {
  description = "Emri i Web App (futeni te GitHub Secret APP_NAME)"
  value       = azurerm_linux_web_app.app.name
}

output "app_url" {
  description = "Adresa e aplikacionit"
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
}
