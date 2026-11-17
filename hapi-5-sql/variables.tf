# variables.tf — hyrjet e konfigurimit (si parametrat e një funksioni).
# Vlerat jepen me terraform.tfvars, me -var, ose me variabla ambienti TF_VAR_<emri>.

variable "subscription_id" {
  description = "ID e subscription-it tuaj në Azure (az account show --query id -o tsv)"
  type        = string
  # pa "default" = e detyrueshme: Terraform e kërkon nëse nuk jepet
}

variable "emri" {
  description = "Emri juaj i vogël, pa hapësira (p.sh. ardian). Përdoret në emrat e burimeve."
  type        = string

  # validation: Terraform ndalon para se të krijojë ndonjë gjë nëse emri nuk është i vlefshëm
  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.emri))
    error_message = "Emri duhet të ketë 2-10 shkronja të vogla ose numra, pa hapësira."
  }
}

variable "location" {
  description = "Rajoni i Azure ku krijohen burimet"
  type        = string
  default     = "swedencentral" # vlerë e paracaktuar; mund të ndryshohet
}

variable "plan_sku" {
  description = "Niveli i App Service Plan. F1 = falas."
  type        = string
  default     = "F1" # për B1 (me pagesë) vendoset plan_sku = "B1"
}
