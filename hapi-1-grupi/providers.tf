# providers.tf — i tregon Terraform-it "me kë do të flasësh" (Azure) dhe cilën version.

terraform {
  required_version = ">= 1.6"

  required_providers {
    # azurerm = provider-i zyrtar për Azure (plugin që di si t'i krijojë burimet)
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  # Azure kërkon të dihet në cilin subscription punojmë (vlera vjen nga variabla)
  subscription_id = var.subscription_id

  # blloku "features" është i detyrueshëm, edhe bosh
  features {}
}
