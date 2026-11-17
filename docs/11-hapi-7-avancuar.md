# 11. Hapi 7 — Të avancuarit: modul, monitorim, mbrojtje, teste, siguri, drift

`hapi-7-avancuar` = `hapi-6-state` + këto shtesa. Backend-i (state në Azure Storage) është i njëjti.
Të gjitha janë **falas** (ose pothuajse), dhe janë testuar me `apply` dhe `destroy` të vërtetë.

```text
hapi-7-avancuar/
├─ modules/webapp/      ← MODULI: App Service Plan + Web App
├─ monitor.tf           ← Log Analytics + Application Insights + alarm 5xx
├─ mbrojtja.tf          ← lock kundër fshirjes + buxhet
└─ tests/               ← terraform test (pa Azure)
```

Si nisni (si te hapi-6): `.\scripts\krijo-state.ps1 -Emri <emri>`, pastaj `terraform init` me `-backend-config` dhe `terraform apply`.
Nëse keni aplikuar `hapi-6` më parë, bëni `init` këtu me të njëjtat vlera: blloqet `moved` e kalojnë plan-in dhe app në modul **pa i fshirë**.

---

## 11.1 Modulet (ripërdorimi)

### Çfarë është një modul?

**Modul** = një folder me skedarë `.tf` që sillet si **funksion** në programim: merr parametra, bën një punë dhe kthen rezultate.

| Në programim (C#) | Në Terraform |
|---|---|
| Parametrat e funksionit | `variables.tf` (hyrjet) |
| Trupi i funksionit | `main.tf` (burimet brenda modulit) |
| Vlera e kthyer (`return`) | `outputs.tf` (daljet) |
| Thirrja `WebApp("ardian", ...)` | blloku `module "webapp" { ... }` |

Në fakt **çdo** projekt Terraform është modul: dosja ku ekzekutoni `terraform apply` quhet *root module* (moduli rrënjë). Ajo që ndërtojmë këtu është një *child module* (modul fëmijë) që thirret nga rrënja.

### Pse na duhen?

1. **Pa përsëritje (DRY).** Plan + Web App + Managed Identity janë 2 burime me 15 rreshta. Pa modul, për 3 aplikacione i kopjojmë 3 herë; me modul i shkruajmë një herë dhe e thërrasim 3 herë.
2. **Një vend për rregullat.** Cilësimet e sigurisë (`https_only`, `ftps_state = "Disabled"`, TLS, HTTP/2) rrinë brenda modulit. Kushdo që e përdor i merr automatikisht; nuk harrohet.
3. **Fsheh kompleksitetin.** Kush e thërret nuk duhet të dijë si krijohet një Linux Web App me identitet; i jep vetëm emrin dhe rajonin.
4. **Teste dhe ndryshime më të sigurta.** Ndryshimi bëhet në një vend.
5. **Ripërdorim mes projekteve.** Moduli mund të jetë në repo tjetër ose në Terraform Registry (`source = "Azure/..."`).

### Struktura e modulit tonë

```text
hapi-7-avancuar/
├─ main.tf              ← moduli rrënjë: e thërret modulin
└─ modules/
   └─ webapp/           ← moduli fëmijë
      ├─ variables.tf   ← HYRJET   (emri, rajoni, plan_sku, app_settings...)
      ├─ main.tf        ← LOGJIKA  (azurerm_service_plan + azurerm_linux_web_app)
      └─ outputs.tf     ← DALJET   (id, name, default_hostname, principal_id)
```

### 1) Hyrjet (`modules/webapp/variables.tf`)

```hcl
variable "emri" {            # e detyrueshme (s'ka default)
  type = string
}
variable "plan_sku" {        # opsionale (ka default)
  type    = string
  default = "F1"
}
variable "app_settings" {
  type    = map(string)
  default = {}
}
```
Variablat pa `default` janë **të detyrueshme**: Terraform ankohet nëse nuk i jepni. Ato me `default` janë opsionale.

### 2) Logjika (`modules/webapp/main.tf`)

```hcl
resource "azurerm_service_plan" "plan" {
  name     = "plan-tf-${var.emri}"      # var.* = hyrja e modulit
  sku_name = var.plan_sku
  ...
}
resource "azurerm_linux_web_app" "app" {
  service_plan_id = azurerm_service_plan.plan.id   # varësi brenda modulit
  app_settings    = var.app_settings               # vijnë nga jashtë
  ...
}
```
Kujdes: moduli **nuk sheh** asgjë nga jashtë vetvetes. Nuk mund të përdorë `azurerm_resource_group.rg` të rrënjës; çdo gjë që i duhet duhet t'i kalohet si hyrje. Kjo e bën të pavarur dhe të testueshëm. Pikërisht ndaj moduli nuk di asgjë për Key Vault ose SQL: referencat e sekreteve i kalon rrënja përmes `app_settings`.

### 3) Daljet (`modules/webapp/outputs.tf`)

```hcl
output "principal_id" {
  value = azurerm_linux_web_app.app.identity[0].principal_id
}
```
Burimet brenda modulit janë **private**. Rrënja sheh vetëm ato që moduli i publikon me `output`. Këtu publikojmë `principal_id` (identiteti i aplikacionit) sepse rrënja i duhet për t'i dhënë rolin *Key Vault Secrets User*.

### 4) Thirrja (`main.tf` i rrënjës)

```hcl
module "webapp" {
  source = "./modules/webapp"              # ku ndodhet moduli

  emri                = local.emri_plote   # ← hyrje
  prapashtesa         = local.prapashtesa
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  plan_sku            = var.plan_sku
  tags                = local.tags

  app_settings = {
    "Blob__Container" = azurerm_storage_container.dokumentet.name
  }
}

# përdorim të daljes së modulit:
resource "azurerm_role_assignment" "app_kv" {
  principal_id = module.webapp.principal_id   # module.<emri>.<dalja>
  ...
}
```
Rregulli i leximit: **hyrja** hyn me `emri = ...`, **dalja** del me `module.webapp.<dalja>`.

### Si duket në `plan` dhe në state

Burimet e modulit marrin prefiks:

```text
module.webapp.azurerm_service_plan.plan
module.webapp.azurerm_linux_web_app.app
```
Provojeni: `terraform state list | Select-String module`.

### Blloku `moved`: refaktorim pa humbje

Në hapin 6 burimet quheshin `azurerm_linux_web_app.app` (pa modul). Nëse thjesht i vendosim në modul, Terraform do t'i shihte si **burime të reja** dhe do **fshinte të vjetrat dhe do krijonte të reja** (aplikacion i humbur!). Blloku

```hcl
moved {
  from = azurerm_linux_web_app.app
  to   = module.webapp.azurerm_linux_web_app.app
}
```
i thotë Terraform-it: "është i njëjti burim, ka ndryshuar vetëm adresa në state". Rezultati: `plan` tregon "has moved", jo shkatërrim.

### Thirrja e shumëfishtë

Fuqia e vërtetë e modulit: një modul, shumë instanca.

```hcl
module "webapp_demo" {
  source              = "./modules/webapp"
  emri                = "${local.emri_plote}demo"
  prapashtesa         = local.prapashtesa
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# ose me for_each, një për student:
module "webapp" {
  for_each            = toset(["ardian", "arjeta", "clirim"])
  source              = "./modules/webapp"
  emri                = each.key
  ...
}
# adresa: module.webapp["ardian"].principal_id
```

### Gabimet e zakonshme

| Gabimi | Shkaku |
|---|---|
| `Missing required argument` te `module` | Harruat një hyrje pa `default` |
| `Unsupported argument` te `module` | Hyrja nuk është deklaruar te `variables.tf` e modulit |
| `Unsupported attribute ... module.webapp.xxx` | Moduli s'e ka `output "xxx"`: shtojeni te `outputs.tf` |
| Pas ndryshimit të `source` s'gjen modulin | Ekzekutoni `terraform init` (e ri-shkarkon/regjistron modulet) |
| `plan` do të fshijë dhe riktijojë pas refaktorimit | Mungon blloku `moved` |

> Rregull praktik: **mos e bëni modul të parakohshëm**. Nëse një grup burimesh e përdorni një herë, mbajeni të thjeshtë. Bëjeni modul kur e përsërisni, ose kur dëshironi të mbyllni rregulla (siguri, emërtim) në një vend.

**Ushtrim:** thirrni modulin dy herë (`module "webapp_demo"` me `plan_sku = "F1"` dhe emër tjetër). Çfarë shfaq `terraform plan`?
(Kujdes: shumë F1 në një rajon mund të kalojnë kuotën; pastaj bëni `destroy`.)

## 11.2 Application Insights (monitorim)

`monitor.tf` krijon:
- **Log Analytics Workspace** (vendi ku ruhen logjet; `daily_quota_gb = 0.1` për siguri kostoje),
- **Application Insights** i lidhur me të,
- setting `APPLICATIONINSIGHTS_CONNECTION_STRING` te Web App,
- (opsionale, kur jepet `alert_email`) **alarm** që dërgon email nëse ka më shumë se 5 gabime HTTP 5xx.

**Verifikim në Portal:** grupi → *Application Insights* → *Live metrics*, *Failures*, *Logs*.
> Për telemetri të plotë, aplikacioni duhet të ketë paketën NuGet `Microsoft.ApplicationInsights.AspNetCore` dhe `builder.Services.AddApplicationInsightsTelemetry();`.
> Pa të, Application Insights ekziston dhe tregon metrikat e Azure (kërkesa, gabime), por jo detajet e brendshme.

## 11.3 Mbrojtja nga fshirja dhe nga kostot

Në `terraform.tfvars` (ose `-var`):
```hcl
mbro_nga_fshirja = true                      # lock CanNotDelete te grupi
alert_email      = "emaili.juaj@example.com" # alarm 5xx + buxhet
buxheti_usd      = 5
```
- **Lock (`azurerm_management_lock`)**: Azure refuzon fshirjen derisa locku të hiqet. Provojeni: `az group delete -n rg-tf-<emri>` → gabim `ScopeLocked`.
  `terraform destroy` funksionon sepse lock-u është ndërtuar të fshihet i pari (`depends_on` te `mbrojtja.tf`).
- **`lifecycle { prevent_destroy = true }`**: mbrojtje brenda Terraform. Shembulli është në koment te `mbrojtja.tf`; provojeni te Key Vault dhe shihni gabimin e `plan` kur bëni `destroy`.
- **Buxheti**: email kur shpenzimi kalon 80% të buxhetit. Mos harroni: buxheti **nuk ndalon** shpenzimin, vetëm njofton.

> Kujdes: me lock aktiv, çdo ndryshim që kërkon **fshirje** burimi (p.sh. heqja e një firewall rule) dështon derisa ta çaktivizoni lock-un (`mbro_nga_fshirja = false`, `apply`).

## 11.4 Testet (`terraform test`)

Skedari `tests/themelore.tftest.hcl` kontrollon rregullat tona **pa krijuar asgjë në Azure** (përdor `mock_provider`):
```powershell
cd hapi-7-avancuar
terraform init -backend=false
terraform test
```
Ka 6 teste: emri i grupit, etiketat, baza falas (`useFreeLimit`), RBAC te Key Vault, refuzimi i emrit të pavlefshëm, alarmi vetëm me email.

**Ushtrim:** ndryshoni `useFreeLimit = false` te `sql.tf` dhe ekzekutoni `terraform test`. Cili test dështon? Kjo është ideja: testet na ndalojnë të prishim rregullat pa e vënë re.

## 11.5 Plan në Pull Request (si koment)

Workflow-i (`.github/workflows/terraform.yml`) tani:
1. kontrollon formatin, 2. ekzekuton **Checkov**, 3. `init`, 4. `validate`, 5. `terraform test` (nëse ka `tests/`),
6. `plan` dhe **e shton rezultatin si koment në PR**, 7. `apply` vetëm pas merge në `main`.

Për të përdorur këtë hap: GitHub → Settings → Secrets and variables → Actions → **Variables** → `TF_DIR` = `hapi-7-avancuar`.
Pa këtë variabël workflow-i punon mbi `hapi-6-state`.

**Ushtrim:** hapni një branch, ndryshoni një tag (`viti = "2026"`), hapni PR, shihni komentin me plan-in; vetëm pastaj bëni merge.

## 11.6 Siguria e kodit me Checkov

Checkov skanon `.tf` kundër qindra rregullave sigurie.
```powershell
pip install checkov
checkov -d hapi-7-avancuar --framework terraform --compact --quiet
```
- Në `hapi-6` raporton ~43 gjetje; në `hapi-7` kemi rregulluar disa të lira (TLS 1.2 te Storage, pa blob publik, FTPS i çaktivizuar, HTTP/2, `content_type` te sekretet): ~36.
- Shumë të tjera mbeten **me qëllim** (plan F1 pa zona, SQL i hapur për mësim, pa Private Endpoint). Është pikërisht lista e asaj që ndryshon për **prodhim**.
- **Ushtrim:** zgjidhni 3 gjetje, lexoni udhëzuesin e rregullit, vendosni nëse e rregulloni ose e pranoni (dhe pse).

## 11.7 Drift (kur dikush ndryshon në Portal)

**Drift** = realiteti në Azure nuk përputhet më me kodin.

1. Pas `apply`, në Portal hapni Web App → Settings → Environment variables → shtoni `DEMO=drift` (ose ndryshoni një tag te grupi).
2. Ekzekutoni `terraform plan`. Terraform e zbulon dhe tregon çfarë do të kthente (`~` për ndryshim, `-` për diçka të shtuar jashtë kodit).
3. Dy zgjidhje:
   - `terraform apply` → Azure kthehet siç thotë kodi (kodi është e vërteta);
   - ose përditësoni kodin që të përmbajë ndryshimin e dëshiruar.
4. Si ta zbulojmë automatikisht: workflow me `schedule:` që ekzekuton `terraform plan -detailed-exitcode` (kodi 2 = ka drift).

**Mësimi:** mos ndryshoni me dorë burime që menaxhon Terraform.

## 11.8 Çfarë u verifikua

- `terraform fmt`, `validate`, `test` (6/6) dhe `checkov` në `hapi-7-avancuar`.
- `apply` i vërtetë me state në Azure Storage (blob `fakulteti.tfstate`), `plan` pas tij = "No changes", pastaj `destroy` i plotë pa gabime (me lock, alarm dhe buxhet aktivë).
