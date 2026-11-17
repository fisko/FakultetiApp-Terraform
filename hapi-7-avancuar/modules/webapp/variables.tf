# Hyrjet e modulit. Kush e thërret modulin (main.tf kryesor) i jep këto vlera.

variable "emri" {
  description = "Emri i studentit (përdoret në emrat e burimeve)"
  type        = string
}

variable "prapashtesa" {
  description = "Prapashtesa e rastësishme për emra unikë"
  type        = string
}

variable "resource_group_name" {
  description = "Grupi ku krijohen burimet"
  type        = string
}

variable "location" {
  description = "Rajoni i Azure"
  type        = string
}

variable "plan_sku" {
  description = "Niveli i planit (F1 = falas)"
  type        = string
  default     = "F1"
}

variable "dotnet_version" {
  description = "Versioni i .NET"
  type        = string
  default     = "10.0"
}

variable "app_settings" {
  description = "Variablat e ambientit të aplikacionit"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Etiketat për çdo burim"
  type        = map(string)
  default     = {}
}
