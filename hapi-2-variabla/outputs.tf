# outputs.tf — vlerat që Terraform na i shfaq në fund të "apply" (ose me "terraform output").

output "resource_group" {
  description = "Emri i grupit të krijuar"
  value       = azurerm_resource_group.rg.name
}

output "storage_account" {
  description = "Emri i Storage account"
  value       = azurerm_storage_account.st.name
}

output "container" {
  description = "Emri i container-it"
  value       = azurerm_storage_container.dokumentet.name
}
