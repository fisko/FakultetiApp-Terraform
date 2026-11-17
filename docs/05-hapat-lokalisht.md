# 5. Hapat 1-5: ndërtojmë infrastrukturën lokalisht

Në çdo hap: **lexoni kodin → `plan` → `apply` → verifikoni në Portal → mendoni pyetjet**.
Çdo hap e gjeni në dosjen e vet (`hapi-1-grupi`, ...). Mund ta shkruani vetë nga fillimi, ose ta kopjoni dosjen dhe të studioni.

Para çdo hapi: `cd hapi-N-...` dhe krijoni `terraform.tfvars`:
```powershell
copy terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars     # subscription_id = "...", emri = "ardian"
```
`emri` = 2-10 shkronja të vogla/numra, pa hapësira. Shembull: `ardian`.

> **Pastrim mes hapave:** para se të kaloni te hapi tjetër, bëni `terraform destroy` te hapi aktual (ose vazhdoni te i njëjti projekt dhe shtoni skedarët). Rekomandimi: **destroy dhe filloni hapin e ri**, kështu praktikoni `destroy` dhe `apply` nga e para.

---

## Hapi 1 — Resource Group (`hapi-1-grupi`)

**Qëllimi:** të ekzekutoni ciklin `init → plan → apply → destroy` me burimin më të thjeshtë.

Kodi i rëndësishëm (`main.tf`):
```hcl
resource "azurerm_resource_group" "rg" {
  name     = "rg-tf-${var.emri}"
  location = var.location
}
```

Komandat:
```powershell
cd hapi-1-grupi
terraform init        # shkarkon provider-in azurerm
terraform fmt
terraform validate    # "Success! The configuration is valid."
terraform plan        # duhet: Plan: 1 to add
terraform apply       # shkruani: yes
```

Verifikim:
```powershell
az group show -n rg-tf-EMRI --query "{emri:name, rajoni:location}" -o table
terraform output
terraform state list      # azurerm_resource_group.rg
```
Portal → *Resource groups* → `rg-tf-<emri>`.

**Eksperiment (shumë i rëndësishëm):**
1. Ekzekutoni `terraform apply` **sërish** → *No changes*. Kjo është idempotenca.
2. Në Portal shtoni me dorë një tag në grup. Ekzekutoni `terraform plan` → çfarë thotë? (Terraform nuk e ndryshon tag-un e shtuar jashtë, sepse nuk e ka në kod. Provoni të shtoni `tags = { a = "b" }` në kod dhe shihni plan-in.)
3. Ndryshoni `location` në `westeurope` dhe bëni `plan` → shihni `-/+` (rikrijim). **Mos e zbatoni.** Ktheni mbrapsht.

Pastrim: `terraform destroy` → yes.

---

## Hapi 2 — Variabla, random dhe Storage (`hapi-2-variabla`)

**Çfarë shtohet:** `random_string` (prapashtesë unike), `locals` (tags), Storage account dhe container.

Pikat kyçe:
- Storage account ka emër **unik globalisht**, 3-24 shkronja të vogla/numra → `st${var.emri}${local.prapashtesa}`.
- `random_string` krijohet një herë dhe ruhet në state, prandaj emri nuk ndryshon në çdo `apply`.
- Burimet referojnë njëri-tjetrin → varësi automatike.

```powershell
cd ..\hapi-2-variabla
terraform init
terraform plan        # Plan: 4 to add (random, grup, storage, container)
terraform apply
terraform output
```

Verifikim:
```powershell
az storage account list -g rg-tf-EMRI --query "[].{emri:name, sku:sku.name}" -o table
az storage container list --account-name <storage_account> --auth-mode login -o table
```
(Nëse kërkon leje: Portal → Storage → Containers.)

**Pyetje:**
- Pse `random_string`? (Emrat duhet të jenë unikë në gjithë botën.)
- Çfarë ndodh nëse në `terraform.tfvars` shkruani `emri = "Ardian"` (me shkronjë të madhe)? (Validimi jep gabim para se të prekë Azure.)
- Çfarë tags ka burimi? Shihni në Portal → Storage → Tags.

Pastrim: `terraform destroy`.

---

## Hapi 3 — App Service Plan dhe Web App (`hapi-3-webapp`)

**Çfarë shtohet:** `azurerm_service_plan` (F1, falas) dhe `azurerm_linux_web_app` (.NET 10) me **Managed Identity**.

Pikat kyçe:
```hcl
resource "azurerm_service_plan" "plan" {
  os_type  = "Linux"
  sku_name = var.plan_sku          # F1 = falas
  ...
}
resource "azurerm_linux_web_app" "app" {
  service_plan_id = azurerm_service_plan.plan.id    # lidhja me planin
  identity { type = "SystemAssigned" }              # identitet për aplikacionin
  site_config {
    always_on = false                               # F1 nuk e mbështet
    application_stack { dotnet_version = "10.0" }
  }
  app_settings = { "Blob__Container" = ... }
}
```

```powershell
cd ..\hapi-3-webapp
terraform init
terraform apply
terraform output app_url
```

Verifikim: hapni `app_url` në shfletues: shihni faqen **bosh/default** të App Service (sepse s'kemi deploy-uar kodin).
Portal → App Service → *Identity* → **System assigned = On**.

**Variabla me rresht komande:** provoni `terraform plan -var="plan_sku=B1"` → shihni `~` update. (Mos e zbatoni; B1 kushton.)

> F1 ka kuotë 60 min CPU/ditë. Nëse aplikacioni ndalet me 403 "Site Disabled", ka mbaruar kuota.

Pastrim: `terraform destroy`.

---

## Hapi 4 — Key Vault, role dhe sekrete (`hapi-4-keyvault`)

**Çfarë shtohet** (në skedar të ri `keyvault.tf`): Key Vault me RBAC, dy role, `time_sleep`, sekreti `StorageConnection`, dhe në Web App një **Key Vault reference**.

Pikat kyçe:
- `data "azurerm_client_config"` — merr kush jeni ju (Terraform ju jep rolin *Secrets Officer*).
- `azurerm_role_assignment` për **aplikacionin** — vetëm *Secrets User* (lexim).
- `time_sleep` 60s: rolet marrin kohë të përhapen; pa të, krijimi i sekretit mund të japë 403.
- Në app **nuk shkruajmë fjalëkalimin**, shkruajmë referencën:
  `@Microsoft.KeyVault(VaultName=...;SecretName=StorageConnection)`.

```powershell
cd ..\hapi-4-keyvault
terraform init
terraform apply        # ~3-5 min (Key Vault dhe pritja 60s)
```

Verifikim:
```powershell
az keyvault secret list --vault-name <key_vault> -o table
```
Portal → Web App → *Environment variables* → `ConnectionStrings__Storage` ka **Key vault Reference** me status ✔ (Resolved). Nëse ka ✘, prisni 1-2 min dhe rifreskoni.

**Pyetje:** Pse aplikacioni merr *Secrets User* dhe jo *Officer*? (Parimi i privilegjit minimal.)

Pastrim: `terraform destroy`. (Key Vault mbetet "soft-deleted" 7 ditë, por emri ka prapashtesë të re në rikrijim, s'ka konflikt.)

---

## Hapi 5 — SQL Server dhe bazë falas (`hapi-5-sql`) = infrastruktura e plotë

**Çfarë shtohet** (`sql.tf`): `random_password`, `azurerm_mssql_server`, **`azapi_resource`** për bazën falas, rregulla firewall, sekreti `SqlConnection`.

Pikat kyçe:
- **Free offer**: provider-i `azurerm` nuk e mbështet ende, ndaj përdorim `azapi` (flet drejtpërdrejt me API-n e Azure). Mësim: *kur provider-i s'e ka një veçori, ka rrugëdalje.*
- Fjalëkalimi gjenerohet nga Terraform (`random_password`): nuk shfaqet në kod. Por **është në state** (dok. 6).
- `AllowAll-VetemPerMesim` (0.0.0.0-255.255.255.255) lejon çdo IP: vetëm për mësim.

```powershell
cd ..\hapi-5-sql
terraform init
terraform plan          # Plan: ~17 to add
terraform apply
terraform output
```

Verifikim:
```powershell
az sql db show -g rg-tf-EMRI -s <sql_server_pa_.database.windows.net> -n db-EMRI `
  --query "{sku:sku.name, falas:useFreeLimit, kur_mbaron:freeLimitExhaustionBehavior}" -o json
```
Duhet `falas: true`. Në Portal: SQL database → banner "**Free offer**".

### Deploy i aplikacionit mbi infrastrukturën tuaj

Aplikacioni vjen nga repo `FakultetiApp` (Mësimi 2). Mënyra më e shpejtë (pa GitHub Actions):

```powershell
git clone https://github.com/fisko/FakultetiApp.git ..\FakultetiApp
cd ..\FakultetiApp
dotnet publish src\FakultetiApp.csproj -c Release -o publish
# zip me rrugë "/" (Compress-Archive në Windows PowerShell 5 prish rrugët; përdorni tar)
cd publish
tar -a -c -f ..\publish.zip *
cd ..
az webapp deploy -g rg-tf-EMRI -n <app_name> --src-path publish.zip --type zip
```
Hapni `<app_url>/Studentet`: lista e studentëve nga SQL (e lidhur me Key Vault). Pastaj Portal → Storage për dokumentet.

> Nuk keni .NET SDK? Hapni `app_url` dhe verifikoni vetëm infrastrukturën; deploy-in e bëjmë me GitHub Actions në dok. 7.

**Pyetje:**
- Hapni `terraform state show random_password.sql`. Çfarë shihni? Pse është e rrezikshme?
- Çfarë ndodh me `terraform plan` nëse fshini me dorë Web App në Portal? (Plan: 1 to add. Terraform e rikrijon!)

Kur të mbaroni: **mos e fshini** nëse vazhdoni me dok. 6; përndryshe `terraform destroy`.

Vazhdoni: [6. State dhe sekretet](06-state-dhe-sekretet.md)
