# backend.tf — ku ruhet "state" (kujtesa e Terraform-it).
# Pa këtë bllok, state ruhet në një skedar lokal (terraform.tfstate). Këtu e çojmë në Azure Storage.
#
# Vlerat NUK shkruhen këtu; i japim te "terraform init" (shih docs/06-state-dhe-sekretet.md):
#   terraform init -backend-config="resource_group_name=..." -backend-config="storage_account_name=..." ...
terraform {
  backend "azurerm" {
    container_name   = "tfstate"
    key              = "fakulteti.tfstate"
    use_azuread_auth = true # hyrje me identitetin tuaj (Entra ID), pa çelësa
  }
}
