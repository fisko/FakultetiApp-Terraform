# 2. Çfarë është Terraform

**Terraform** është një program (një skedar `terraform.exe`) që lexon skedarët tuaj `.tf`, krahason atë që dëshironi me atë që ekziston në cloud, dhe bën ndryshimet e nevojshme.

```text
  skedarët .tf  ──►  terraform  ──►  Azure (përmes API)
  (çfarë dua)         │
                      └──► state (çfarë ka krijuar deri tani)
```

Shkruhet në gjuhën **HCL** (HashiCorp Configuration Language): e thjeshtë, si JSON i lexueshëm, me komente `#`.

## Konceptet bazë

### 1. Provider
Plugin që i mëson Terraform-it si të flasë me një shërbim. Terraform vetë nuk di asgjë për Azure; e di `azurerm`.

```hcl
terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
  }
}
provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}
```
`terraform init` i shkarkon providerat në dosjen `.terraform/`.

### 2. Resource (burim)
Një gjë që Terraform **krijon dhe menaxhon**.

```hcl
resource "azurerm_resource_group" "rg" {   # resource "LLOJI" "EMRI_LOKAL"
  name     = "rg-tf-ardian"
  location = "swedencentral"
}
```
- `azurerm_resource_group` = lloji (nga provider-i)
- `rg` = emri në kod; e referoni me `azurerm_resource_group.rg`
- brenda `{ }` janë vetitë (argumentet)

### 3. Data source
**Lexon** diçka që ekziston tashmë, pa e krijuar.
```hcl
data "azurerm_client_config" "current" {}   # kush jam unë, cili tenant
# përdorim: data.azurerm_client_config.current.tenant_id
```

### 4. Variable (hyrje)
Parametra të konfigurimit, si argumentet e një funksioni. Vlerat vijnë nga `terraform.tfvars`, nga `-var`, ose nga variablat e mjedisit `TF_VAR_emri`.
```hcl
variable "emri" {
  type        = string
  description = "Emri juaj i vogël"
}
# përdorim: var.emri
```

### 5. Local
Vlerë e llogaritur brenda kodit, për të mos e përsëritur.
```hcl
locals { tags = { studenti = var.emri } }
# përdorim: local.tags
```

### 6. Output (dalje)
Çfarë shfaq Terraform në fund (p.sh. URL e aplikacionit).
```hcl
output "app_url" { value = "https://${azurerm_linux_web_app.app.default_hostname}" }
```

### 7. Referencat dhe varësitë
Kur një burim përdor vlerën e tjetrit (`azurerm_resource_group.rg.name`), Terraform kupton **rendin**: krijon grupin para storage-it. Kjo quhet *graf varësish*. Terraform krijon në paralel çka nuk varet nga njëri-tjetri.

Kur varësia nuk shihet në kod, e shkruani vetë me `depends_on = [...]`.

### 8. State (gjendja)
Skedari `terraform.tfstate`: Terraform e ruan aty **çfarë ka krijuar** dhe ID-të e burimeve. Pa të, nuk do dinte që `rg` në kod është ai grup konkret në Azure.

> Rregulla: state **nuk fshihet, nuk ndryshohet me dorë, nuk publikohet në Git** (përmban sekrete). Në ekip ruhet në vend të përbashkët (Azure Storage), shih [dok. 6](06-state-dhe-sekretet.md).

## Cikli i punës (5 komandat)

| Komanda | Çfarë bën | Ndryshon Azure? |
|---|---|---|
| `terraform init` | Shkarkon providerat, përgatit backend-in | Jo |
| `terraform fmt` | Rirenditë kodin në stilin standard | Jo |
| `terraform validate` | Kontrollon sintaksën | Jo |
| `terraform plan` | **Tregon çfarë do të ndryshojë** (+ krijohet, ~ ndryshon, - fshihet) | Jo |
| `terraform apply` | Zbaton planin (kërkon "yes") | **Po** |
| `terraform destroy` | Fshin gjithçka që menaxhon | **Po** |

Si lexohet plan-i:

```text
  + krijohet        ~ ndryshohet në vend       - fshihet       -/+ fshihet e rikrijohet
Plan: 5 to add, 0 to change, 0 to destroy.
```

**Zakoni i artë: gjithmonë lexoni `plan` para `apply`.** Veçanërisht `-` dhe `-/+` (humbje të dhënash!).

## Terraform kundrejt asaj që bëmë me `az`

| `az` (Mësimi 2) | Terraform |
|---|---|
| `az group create -n rg-x -l swedencentral` | `resource "azurerm_resource_group" ...` |
| `az webapp create ...` | `resource "azurerm_linux_web_app" ...` |
| `az keyvault secret set ...` | `resource "azurerm_key_vault_secret" ...` |
| Përsëritja jep gabim | Përsëritja nuk ndryshon asgjë |

Vazhdoni: [3. Si organizohet një projekt](03-organizimi.md)
