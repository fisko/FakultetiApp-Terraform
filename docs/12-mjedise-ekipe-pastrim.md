# 12 — Mjedise (dev/prod), puna në ekip dhe pastrimi automatik

Tre tema për kur projekti rritet: **disa mjedise**, **ekipe** dhe **kontroll i kostos**.

## 1. Mjedise `dev` dhe `prod` me `tfvars`

Kodi është i njëjtë; ndryshojnë vetëm vlerat. Çdo mjedis ka skedarin e vet në `hapi-7-avancuar/envs/`:

| Skedari | Qëllimi |
|---|---|
| `envs/dev.tfvars` | F1, pa lock, përdoret për prova |
| `envs/prod.tfvars` | F1, lock `CanNotDelete`, alarm me email (opsional) |

Variabla `mjedisi` (`dev` ose `prod`) shtohet në emra: `rg-tf-<emri>dev`, `rg-tf-<emri>prod`. Kështu dy mjedise nuk përplasen.

### Lokalisht

```powershell
cd hapi-7-avancuar
terraform init -backend-config="key=fakulteti-dev.tfstate" -reconfigure
terraform plan  -var-file=envs/dev.tfvars
terraform apply -var-file=envs/dev.tfvars
```

**Rregull i artë:** çdo mjedis ka **state-in e vet** (`key=fakulteti-<mjedisi>.tfstate`). Nëse ndani state, `dev` mund të fshijë `prod`.

### Në GitHub Actions

- Variabla e repo-s `TF_ENV` (`dev`/`prod`) ose zgjedhja `mjedisi` kur nisni workflow-n me dorë.
- Workflow-i zgjedh vetë `key` të state dhe `-var-file`.
- Për `prod`: Settings → **Environments** → `prod` → *Required reviewers*. Apply pret miratimin e një njeriu.

## 2. Puna në ekip

**Opsioni A — `azurerm` backend + OIDC (ai që përdorim).**
State në Azure Storage, identiteti i workflow-t me OIDC (pa fjalëkalime). Falas, ju kontrolloni gjithçka. Kufizim: kyçja e state bëhet nga blob lease; role dhe miratimet i ndërtoni vetë.

**Opsioni B — Terraform Cloud (HCP Terraform).**
```hcl
terraform {
  cloud {
    organization = "fakulteti"
    workspaces { name = "fakulteti-dev" }
  }
}
```
- Plan/apply ekzekutohen në cloud, state dhe kyçja menaxhohen për ju.
- Një *workspace* për mjedis (zëvendëson `key=`).
- Kredencialet Azure me **dynamic provider credentials** (OIDC), pa sekrete të ruajtura.
- Ka plan falas për ekipe të vogla; shton UI, historik runs, policy.

| | Azure Storage + OIDC | Terraform Cloud |
|---|---|---|
| Kosto | ~0 | falas në nivel bazë |
| Setup | skriptat tona | llogari + workspace |
| UI dhe historik | GitHub Actions | i brendshëm |
| Kontroll | i plotë | i ndarë me ofruesin |

Për klasën rekomandojmë A; B kur ekipi rritet.

**Rolet në ekip:** jepni `Contributor` në RG (jo `Owner` në subscription) dhe `Storage Blob Data Contributor` vetëm te storage i state-it.

## 3. Pastrimi automatik

Harrimi i burimeve = faturë. Kemi tre mburoja.

1. **Etiketa `skadon`** (`skadon = "2026-12-31"`) në `terraform.tfvars`. Burimi merr tag `skadon`.
2. **Skripta `scripts/pastro-skaduar.ps1`** gjen grupet `rg-tf-*` me `skadon` në të kaluarën.
   ```powershell
   ./scripts/pastro-skaduar.ps1          # provë, vetëm liston
   ./scripts/pastro-skaduar.ps1 -Fshi    # heq lock, fshin buxhetin, fshin grupin
   ```
3. **Workflow `pastrim.yml`** (Actions → *Pastrim*):
   - `menyra = terraform`: bën `terraform destroy` (shkruani `FSHI` për konfirmim).
   - `menyra = skaduar`: ekzekuton skriptën me `-Fshi`.
   - Çdo javë automatikisht, **vetëm** nëse variabla e repo-s `AUTO_PASTRIM = true`.

> Shënim: buxheti është objekt i nivelit subscription, ndaj skripta e fshin vetë.
> `terraform destroy` nuk fshihet nga `CanNotDelete` sepse lock-u krijohet i fundit dhe fshihet i pari.

## Çfarë u provua realisht

- `plan` në pull request me koment + Checkov: **kaloi**.
- Apply në `main` me OIDC dhe state në Azure Storage: **kaloi** (FTPS `Disabled`, TLS 1.2, HTTP/2 të konfirmuara me `az webapp show`).
- `oidc-github.ps1` dhe `krijo-state.ps1`: **kaluan**.
- `pastrim.yml` me `terraform`: **kaloi** (burimet u fshinë).
- Mënyra `skaduar` provuar vetëm si provë (dry-run).

## Ushtrime

1. Krijoni `dev` dhe `prod` në state të ndara; verifikoni që `terraform state list` ndryshon.
2. Vendosni `skadon` për nesër dhe nisni `pastro-skaduar.ps1` pa `-Fshi`.
3. Shtoni Environment `prod` me miratim në GitHub dhe provoni një apply.
