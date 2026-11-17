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

**Modul** = folder me skedarë `.tf` që sillet si funksion: ka hyrje (`variables.tf`), logjikë (`main.tf`) dhe dalje (`outputs.tf`).

Në `main.tf`:
```hcl
module "webapp" {
  source              = "./modules/webapp"
  emri                = var.emri
  resource_group_name = azurerm_resource_group.rg.name
  ...
}
```
- Referojmë daljet e modulit: `module.webapp.principal_id`.
- Pse? Nëse duhen 3 aplikacione, thërrasim modulin 3 herë; kodi shkruhet një herë.
- Blloku `moved { from = ... to = module.webapp... }` tregon se burimi ndryshoi vend, jo që duhet të fshihet.

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
