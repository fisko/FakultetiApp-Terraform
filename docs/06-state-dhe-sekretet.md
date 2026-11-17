# 6. State në Azure dhe menaxhimi i sekreteve

## 6.1 Çfarë është state dhe pse na intereson

Deri tani state ishte **lokal**: skedari `terraform.tfstate` në dosjen tuaj. Probleme:

| Problem | Pasoja |
|---|---|
| Fshini dosjen/kompjuterin | Terraform "harron" çfarë krijoi; burimet mbeten jetime në Azure |
| Dy persona punojnë | Secili ka state të vetin → konflikte, dublikime |
| GitHub Actions | Nuk e ka skedarin tuaj lokal |
| Përmban sekrete | Fjalëkalimi SQL dhe çelësat janë aty në tekst të hapur |

Zgjidhja: **remote state** (state i largët) në **Azure Storage**, me:
- **Locking**: dy `apply` njëkohësisht nuk lejohen (blob lease).
- **Versionim/backup** i mundshëm.
- Hyrje me **Entra ID** (identiteti juaj), pa çelësa.

## 6.2 Problemi "e pashkrimi": ku ruhet state?

State duhet të ekzistojë **para** Terraform-it, ndaj këtë një burim e krijojmë me skriptë CLI (një herë):

```powershell
cd FakultetiApp-Terraform
az login
.\scripts\krijo-state.ps1 -Emri ardian
```
Skripta krijon `rg-tfstate-<emri>`, storage `sttf<emri><5shkronja>`, container `tfstate`, dhe ju jep rolin *Storage Blob Data Contributor*.
Në fund printon komandën `terraform init` të gatshme; **ruajeni**.

> Storage i state është **veçmas** nga infrastruktura që menaxhon Terraform; kështu `terraform destroy` nuk e fshin state-in me vete.

## 6.3 Përdorimi i backend-it (`hapi-6-state`)

`hapi-6-state` = `hapi-5-sql` + skedari `backend.tf`:
```hcl
terraform {
  backend "azurerm" {
    container_name   = "tfstate"
    key              = "fakulteti.tfstate"
    use_azuread_auth = true
  }
}
```
Vlerat e tjera (`resource_group_name`, `storage_account_name`, `subscription_id`) i japim te `init` (konfigurim i pjesshëm), që të mos i shkruajmë në kod:

```powershell
cd hapi-6-state
copy terraform.tfvars.example terraform.tfvars    # plotësoni
terraform init -backend-config="resource_group_name=rg-tfstate-ardian" `
               -backend-config="storage_account_name=sttfardianXXXXX" `
               -backend-config="subscription_id=<subscription_id>"
terraform apply
```

Verifikim: Portal → `rg-tfstate-<emri>` → Storage → Containers → `tfstate` → blob `fakulteti.tfstate`.
Provoni: dosja lokale **nuk ka** `terraform.tfstate`.

**Migrimi nga state lokal:** nëse kishit infrastrukturë me state lokal (hapi-5), kur bëni `init` në projekt me backend, Terraform pyet *"Do you want to copy existing state?"* → `yes`. Në klasë më e thjeshtë: `terraform destroy` në hapi-5, pastaj hapi-6 nga e para.

## 6.4 Ku janë sekretet? (Rrezik i ndershëm)

| Vend | Çfarë ka | Mbrojtja |
|---|---|---|
| Kodi `.tf` | Asnjë sekret (përdorim `random_password`, referenca) | Mund të jetë në Git |
| `terraform.tfvars` | `subscription_id`, emri | `.gitignore` (nuk është sekret i fortë) |
| **State** | **Fjalëkalimi SQL, connection strings, çelësat** në tekst të hapur | Backend privat + Entra ID, **kurrë Git** |
| Key Vault | Connection strings | RBAC; aplikacioni lexon me Managed Identity |
| GitHub Secrets | `AZURE_CLIENT_ID`... (identifikues, jo fjalëkalime) | OIDC: **asnjë fjalëkalim** |

Rregulla:
1. **Kurrë** mos bëni commit `*.tfstate` ose `terraform.tfvars` me sekrete. `.gitignore` i mbron.
2. Mos vendosni fjalëkalime në kod: gjenerojini (`random_password`) ose merrini nga Key Vault.
3. Ruani state në **backend privat** me akses të kufizuar.
4. Në prodhim: shmangni fjalëkalimet krejt, përdorni **Entra ID authentication** në SQL (aplikacioni hyn me Managed Identity).

## 6.5 `.terraform.lock.hcl`
Fikson versionet e provider-ave. Ngarkojeni në Git, që të gjithë (dhe GitHub Actions) të përdorin të njëjtat versione. Përditësohet me `terraform init -upgrade`.

Vazhdoni: [7. GitHub Actions](07-github-actions.md)
