# outputs.tf — vlerat që Terraform na i shfaq në fund të "apply".

output "resource_group" {
  description = "Emri i grupit të krijuar"
  value       = azurerm_resource_group.rg.name
}
