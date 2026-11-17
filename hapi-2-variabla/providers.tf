# providers.tf — i tregon Terraform-it "me kë do të flasësh" dhe cilat versione.
# Provider = plugin që e përkthen kodin tonë në thirrje drejt një shërbimi (Azure, etj.).
# "terraform init" i shkarkon dhe i regjistron versionet te .terraform.lock.hcl (skedari commit-ohet).

terraform {
  required_version = ">= 1.6" # versioni minimal i Terraform CLI

  required_providers {
    # azurerm = provider-i zyrtar për Azure
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0" # çdo 4.x, por jo 5.0
    }
    # random = gjeneron vlera të rastësishme (prapashtesa e emrave)
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  # Azure kërkon të dihet në cilin subscription punojmë (vlera vjen nga variabla)
  subscription_id = var.subscription_id

  # blloku "features" është i detyrueshëm, edhe bosh
  features {}
}
