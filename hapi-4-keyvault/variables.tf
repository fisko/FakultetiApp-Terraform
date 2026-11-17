variable "subscription_id" {
  description = "ID e subscription-it tuaj në Azure (az account show --query id -o tsv)"
  type        = string
}

variable "emri" {
  description = "Emri juaj i vogël, pa hapësira (p.sh. ardian). Përdoret në emrat e burimeve."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.emri))
    error_message = "Emri duhet të ketë 2-10 shkronja të vogla ose numra, pa hapësira."
  }
}

variable "location" {
  description = "Rajoni i Azure ku krijohen burimet"
  type        = string
  default     = "swedencentral"
}

variable "plan_sku" {
  description = "Niveli i App Service Plan. F1 = falas."
  type        = string
  default     = "F1"
}
