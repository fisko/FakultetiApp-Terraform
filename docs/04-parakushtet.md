# 4. Parakushtet (bëjini para orës)

## 4.1 Subscription në Azure

Duhet një subscription **i juaji** (jo i profesorit). Opsione:

- **Azure for Students** (me email universiteti, pa kartë): <https://azure.microsoft.com/free/students>
- **Free account** (200 USD kredit 30 ditë, kërkon kartë për verifikim): <https://azure.microsoft.com/free>

Kontrolli: Portal → *Subscriptions* → duhet të shihni një me status **Active**.

> Nëse nuk keni asnjë, tregojini profesorit para orës; ka zgjidhje alternative.

## 4.2 Instaloni mjetet

| Mjeti | Windows (PowerShell) | macOS | Verifikimi |
|---|---|---|---|
| Azure CLI | `winget install Microsoft.AzureCLI` | `brew install azure-cli` | `az version` |
| Terraform | `winget install Hashicorp.Terraform` | `brew install terraform` | `terraform version` |
| Git | `winget install Git.Git` | `brew install git` | `git --version` |
| VS Code (opsional) | `winget install Microsoft.VisualStudioCode` | `brew install --cask visual-studio-code` | |

Pas instalimit **mbyllni dhe hapni përsëri** PowerShell. Nëse `winget` nuk punon: shkarkoni Terraform nga <https://developer.hashicorp.com/terraform/install> (zip), nxirreni `terraform.exe` në një dosje dhe shtojeni në PATH.

VS Code: instaloni zgjerimin **HashiCorp Terraform** (ngjyra, plotësim automatik, `fmt` kur ruani).

## 4.3 Kyçuni në Azure

```powershell
az login                          # hapet shfletuesi
az account list -o table          # shihni subscription-et tuaja
az account set --subscription "EMRI-OSE-ID"   # nëse keni më shumë se një
az account show --query "{emri:name, id:id, tenant:tenantId}" -o table
```

Shënoni `id` = **subscription_id** juaj. Do ta përdorni shpesh.

## 4.4 Regjistroni shërbimet (një herë për subscription të ri)

Në subscription të ri disa shërbime nuk janë "aktivizuar", dhe Terraform dështon me *MissingSubscriptionRegistration*. Aktivizojini:

```powershell
foreach ($p in "Microsoft.Web","Microsoft.KeyVault","Microsoft.Sql","Microsoft.Storage","Microsoft.Authorization") {
  az provider register --namespace $p
}
# kontroll (duhet "Registered" për të gjitha, mund të marrë 2-5 min)
foreach ($p in "Microsoft.Web","Microsoft.KeyVault","Microsoft.Sql","Microsoft.Storage") {
  "$p : " + (az provider show --namespace $p --query registrationState -o tsv)
}
```

## 4.5 Klononi repon

```powershell
git clone https://github.com/fisko/FakultetiApp-Terraform.git
cd FakultetiApp-Terraform
```

Më vonë (dok. 7) do ta bëni **fork** ose do ta ngarkoni në repon tuaj.

## 4.6 Lista e kontrollit

- [ ] `az account show` tregon subscription-in tuaj
- [ ] `terraform version` printon 1.6 ose më të ri
- [ ] 4 shërbimet janë `Registered`
- [ ] Repo është klonuar

Vazhdoni: [5. Hapat lokalisht](05-hapat-lokalisht.md)
