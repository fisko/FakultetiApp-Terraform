# Daljet e modulit: vetëm ato që duhen jashtë (p.sh. për të dhënë rolin te Key Vault).

output "id" {
  description = "ID e plotë e Web App në Azure"
  value       = azurerm_linux_web_app.app.id
}

output "name" {
  description = "Emri i Web App"
  value       = azurerm_linux_web_app.app.name
}

output "default_hostname" {
  description = "Adresa (hostname) e aplikacionit"
  value       = azurerm_linux_web_app.app.default_hostname
}

output "principal_id" {
  description = "Object ID i Managed Identity të aplikacionit"
  value       = azurerm_linux_web_app.app.identity[0].principal_id
}
