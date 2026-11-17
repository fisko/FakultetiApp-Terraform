# 9. Pastrimi, kostot dhe problemet e zakonshme

## 9.1 Pastrimi

```powershell
cd hapi-N-...            # dosja ku bëtë apply
terraform destroy        # shkruani yes
```
Fshin vetëm çfarë ka krijuar Terraform (sipas state). Pastaj fshini edhe state storage nëse mbaruat krejt:
```powershell
az group delete -n rg-tfstate-EMRI --yes --no-wait
```
Kontroll final: Portal → *Resource groups* → s'duhet të ketë `rg-tf-*` ose `rg-tfstate-*`.
Nëse `terraform destroy` dështon në mes, ekzekutojeni sërish; ose fshini me dorë `az group delete -n rg-tf-EMRI --yes`.

## 9.2 Kostot

| Burimi | Kosto |
|---|---|
| App Service Plan **F1** | Falas (60 min CPU/ditë) |
| SQL Database **free offer** | Falas (100,000 vCore-sek/muaj, 32 GB); pas kufirit pauzohet |
| Storage LRS | Qindarka/muaj për të dhëna të pakta |
| Key Vault standard | Qindarka për operacione |
| Terraform, GitHub Actions (repo publike) | Falas |
| **B1** ose më lart | **~13 USD/muaj**: mos e vendosni pa arsye |

Çdo subscription ka vetëm **një** ofertë falas SQL për bazë deri 10 baza. Vendosni një **Budget** me alarm: Portal → *Cost Management → Budgets* (p.sh. 5 USD).

## 9.3 Gabimet e zakonshme

| Mesazhi | Shkaku | Zgjidhja |
|---|---|---|
| `terraform: command not found` | S'është instaluar / PATH | Instaloni, hapni terminal të ri |
| `Error: subscription_id is a required provider property` | Mungon `terraform.tfvars` | Krijoni nga `.example` |
| `MissingSubscriptionRegistration` | Shërbimi s'është regjistruar | Hapi 4.4 i dok. 4 |
| `Invalid value for variable: Emri duhet...` | `emri` me shkronja të mëdha/hapësira | Vetëm `a-z0-9`, 2-10 karaktere |
| `StorageAccountAlreadyTaken` / `already exists` | Emër i zënë | Ndryshoni `emri` ose `terraform destroy` + `apply` (random i ri) |
| `RequestDisallowedByAzure` / `location not available` | Rajoni i kufizuar (Azure for Students) | `terraform apply -var="location=northeurope"` ose rajon tjetër të lejuar |
| `Unauthorized`/`403` te Key Vault secret | Rolet s'janë përhapur | Prisni 2 min dhe `terraform apply` sërish |
| `Quota ... F1` / `Free VMs: 0` | S'keni kuotë F1 në atë rajon | Provoni rajon tjetër; ose `plan_sku = "B1"` (kushton) |
| `SqlServerRegionDoesNotAllowProvisioning` | Rajon pa kapacitet SQL për subscription të ri | Ndryshoni `location` (p.sh. `northeurope`, `uksouth`) |
| `Error acquiring the state lock` | Dikush/diçka tjetër po bën apply, ose një komandë u ndërpre (Ctrl+C) dhe lock-u mbeti | Prisni; nëse ka mbetur ngecur: `terraform force-unlock <ID>` (ID-ja shfaqet në gabim). Vetëm kur jeni të sigurt që asgjë tjetër nuk po punon |
| `ScopeLocked` gjatë `delete`/`destroy` | Grupi ka lock `CanNotDelete` | Çaktivizoni `mbro_nga_fshirja`, `apply`, pastaj fshini; ose `az lock delete --name mos-fshij -g <grupi>` |
| Buxheti ekziston por grupi u fshi me dorë (`already exists ... budgets`) | Buxheti jeton veçmas nga grupi | `az consumption budget delete --budget-name buxhet-<emri> --resource-group <grupi>` |
| `Backend configuration changed` | Ndryshuat backend | `terraform init -reconfigure` ose `-migrate-state` |
| `Provider produced inconsistent result` | Gabim kalimtar i Azure | Ekzekutoni `apply` sërish |
| Faqja jep 403 "Site Disabled" | Kuota F1 mbaroi | Prisni deri nesër |
| `/Studentet` jep 500 | Sekreti i KV s'u lexua / s'ka deploy | Portal → Environment variables: reference ✔? Rindizni app |

## 9.4 Mjete të dobishme

```powershell
terraform fmt -recursive      # formaton
terraform validate            # kontrollon
terraform state list          # çfarë menaxhon
terraform state show <burimi> # detajet e një burimi
terraform output              # daljet
terraform plan -out=tfplan    # ruan planin; terraform apply tfplan e zbaton saktësisht
terraform graph               # grafi i varësive (DOT)
TF_LOG=DEBUG terraform plan   # log i detajuar (PowerShell: $env:TF_LOG="DEBUG")
```
