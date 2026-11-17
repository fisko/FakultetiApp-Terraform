# main.tf — burimet që duam të ekzistojnë. Këtu: vetëm një Resource Group.

# Sintaksa:  resource "<LLOJI>" "<EMRI_LOKAL>" { ... }
#   LLOJI       = çfarë krijohet (azurerm_resource_group)
#   EMRI_LOKAL  = si e quajmë në kod (nuk është emri në Azure)
resource "azurerm_resource_group" "rg" {
  name     = "rg-tf-${var.emri}" # emri në Azure
  location = var.location
}
