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

variable "alert_email" {
  description = "Email për alarmet dhe buxhetin. Bosh = pa alarme (default)."
  type        = string
  default     = ""
}

variable "mjedisi" {
  description = "Mjedisi: bosh (pa mjedis), dev ose prod. Shtohet te emrat e burimeve, p.sh. rg-tf-ardiandev."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^(|dev|prod)$", var.mjedisi))
    error_message = "mjedisi duhet të jetë bosh, dev ose prod."
  }
}

variable "skadon" {
  description = "Data (YYYY-MM-DD) pas së cilës pastrimi automatik mund ta fshijë grupin. Bosh = nuk skadon."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^(|[0-9]{4}-[0-9]{2}-[0-9]{2})$", var.skadon))
    error_message = "skadon duhet të jetë bosh ose në formatin YYYY-MM-DD."
  }
}

variable "buxheti_usd" {
  description = "Buxheti mujor i grupit në USD (përdoret vetëm kur alert_email është dhënë)"
  type        = number
  default     = 5

  validation {
    condition     = var.buxheti_usd > 0
    error_message = "Buxheti duhet të jetë më i madh se 0."
  }
}

variable "mbro_nga_fshirja" {
  description = "true = vendos lock CanNotDelete te grupi (terraform destroy e heq vetë)"
  type        = bool
  default     = false
}
