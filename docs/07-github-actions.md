# 7. Terraform me GitHub Actions (CI/CD për infrastrukturën)

Qëllimi: infrastruktura ndryshohet **vetëm nëpërmjet Git**.

```text
  Ndryshoni .tf  ──►  Pull Request  ──►  Actions: fmt + validate + PLAN   (shihni çfarë do të ndryshojë)
                          │
                       Merge në main  ──►  Actions: APPLY                  (ndryshon Azure)
```

Workflow-i: `.github/workflows/terraform.yml`. Punon mbi `hapi-6-state/`.

## 7.1 Si hyn GitHub në Azure-in tuaj: OIDC (pa fjalëkalim)

Njësoj si në Mësimin 2, por tani në **tenant-in dhe subscription-in tuaj**:
1. Krijoni një *app registration* (identitet) në Entra ID tuajin.
2. I thoni Azure: "beso workflow-t e repos `përdoruesi/repo` në `main` dhe në `pull_request`" (*federated credential*).
3. I jepni lejet (Owner në subscription për mësim; Blob Data Contributor në state).
4. Workflow-i merr token afatshkurtër nga GitHub dhe e shkëmben me Azure.

Skripta i bën të gjitha:

## 7.2 Hapat

**1. Repo juaj në GitHub.** Bëni *Fork* të `fisko/FakultetiApp-Terraform` (emri mbetet i njëjtë), ose krijoni repo të re dhe ngarkoni skedarët.

**2. State** (nëse s'e keni bërë në dok. 6):
```powershell
.\scripts\krijo-state.ps1 -Emri ardian
```

**3. Identiteti për GitHub:**
```powershell
.\scripts\oidc-github.ps1 -GitHubRepo "PERDORUESI/FakultetiApp-Terraform" `
    -StateRg "rg-tfstate-ardian" -StateStorage "sttfardianXXXXX"
```
Printon 3 sekrete dhe 3 variabla.

> Nëse repo (fork) nuk ekziston kur e ekzekutoni, ekzekutojeni **sërish pasi ta krijoni**: skripta shton edhe subject-in me ID-të e GitHub.

**4. GitHub → repo → Settings → Secrets and variables → Actions**

| Tab | Emri | Vlera |
|---|---|---|
| Secrets | `AZURE_CLIENT_ID` | nga skripta |
| Secrets | `AZURE_TENANT_ID` | nga skripta |
| Secrets | `AZURE_SUBSCRIPTION_ID` | nga skripta |
| Variables | `TF_EMRI` | emri juaj (p.sh. `ardian`) |
| Variables | `STATE_RG` | `rg-tfstate-ardian` |
| Variables | `STATE_STORAGE` | `sttfardianXXXXX` |

Pse `variables` dhe jo `secrets` për tre të fundit? Nuk janë sekrete, dhe duam t'i shohim në log.

**5. Actions → Settings → "Allow all actions"** nëse është çaktivizuar (në fork Actions mund të jetë off: hyni te tab *Actions* → *I understand, enable them*).

**6. Provoni:**

a) *Plan në pull request:*
```powershell
git checkout -b ndrysho-tags
# ndryshoni hapi-6-state/main.tf: p.sh. në locals.tags shtoni  viti = "2026"
git add . ; git commit -m "Shtoj tag viti" ; git push -u origin ndrysho-tags
```
Hapni **Pull Request** në GitHub. Te *Actions* shihni job-in `terraform`; hapni hapin **Plan** → lexoni `~ update in-place`.

b) *Apply me merge:* **Merge** pull request-in → workflow-i niset në `main` → hapi **Apply** zbaton. Verifikoni tag-un në Portal.

c) *Provoni gabim:* shkruani qëllimisht kod të pavlefshëm → hapi **Validate** dështon → PR nuk duhet bashkuar.

## 7.3 Shënime të rëndësishme

- **Mos bëni `apply` lokal dhe nga Actions njëkohësisht**: state ka *lock*, dhe i dyti pret/dështon (e mirë).
- Hapi **Format** dështon nëse kodi s'është formatuar: ekzekutoni `terraform fmt -recursive` para commit.
- `.terraform.lock.hcl` duhet të jetë në repo (ekzekutoni `terraform init` në `hapi-6-state` dhe bëni commit).
- **Rrezik realist**: kushdo që bashkon në `main` ndryshon Azure. Në ekip shtohen: *branch protection* (PR i detyrueshëm), *Environment* me miratim manual për `apply`, dhe leje më të ngushta se Owner.

## 7.4 Nëse dështon

| Gabimi | Shkaku | Zgjidhja |
|---|---|---|
| `AADSTS700213 No matching federated identity record` | Subject i panjohur (emri i repos/branch/fork) | Ekzekutoni `oidc-github.ps1` sërish pasi forku ekziston; kontrolloni që repo quhet saktë |
| `AADSTS700016 Application not found` | `AZURE_CLIENT_ID` ose `AZURE_TENANT_ID` i gabuar | Kopjojini saktësisht nga skripta |
| `AuthorizationFailed` në Apply | Identiteti s'ka rol të mjaftueshëm | Skripta jep Owner; kontrolloni te Subscription → Access control (IAM) |
| `403 ... AuthorizationPermissionMismatch` në Init | Mungon *Storage Blob Data Contributor* | `oidc-github.ps1` e jep; pritni 2 min |
| `Error: Backend initialization required` | Mungon `init` | Workflow-i e bën vetë; lokalisht ekzekutoni `terraform init ...` |

Vazhdoni: [8. Detyrat](08-detyrat.md)
