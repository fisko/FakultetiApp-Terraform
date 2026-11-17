<#
.SYNOPSIS
  Krijon identitetin (app registration) që GitHub Actions përdor për të hyrë në Azure-in TUAJ me OIDC (pa fjalëkalim),
  e lejon të krijojë burime dhe të shkruajë state, dhe printon vlerat për GitHub Secrets.

.EXAMPLE
  ./scripts/oidc-github.ps1 -GitHubRepo "emri-juaj/FakultetiApp-Terraform" -StateStorage "sttfardianabc12" -StateRg "rg-tfstate-ardian"
#>
param(
    [Parameter(Mandatory)][string]$GitHubRepo,     # owner/repo i repos suaj në GitHub
    [Parameter(Mandatory)][string]$StateStorage,   # storage account i state (nga krijo-state.ps1)
    [Parameter(Mandatory)][string]$StateRg,        # grupi i tij
    [string]$Name = "gh-terraform"
)
$ErrorActionPreference = "Stop"

$sub    = az account show --query id -o tsv
$tenant = az account show --query tenantId -o tsv
if (-not $sub) { throw "Nuk jeni kyçur. Ekzekutoni: az login" }

# 1) App registration + service principal (identiteti i workflow-t)
$appId = az ad app list --display-name $Name --query "[0].appId" -o tsv
if (-not $appId) { $appId = az ad app create --display-name $Name --query appId -o tsv }
if (-not (az ad sp list --filter "appId eq '$appId'" --query "[0].id" -o tsv)) { az ad sp create --id $appId -o none }

# 2) Lejet. Terraform krijon burime dhe dhënë role (Key Vault), prandaj duhet Owner.
#    Është subscription i juaji për mësim; në prodhim jepet leje më e ngushtë.
az role assignment create --assignee $appId --role Owner --scope "/subscriptions/$sub" -o none
#    Leje për të lexuar/shkruar state në Storage (Entra ID)
$stId = az storage account show -n $StateStorage -g $StateRg --query id -o tsv
az role assignment create --assignee $appId --role "Storage Blob Data Contributor" --scope $stId -o none

# 3) Subjects: workflow në branch main (apply) dhe në pull request (plan).
#    GitHub ndonjëherë i dërgon me ID (owner@id/repo@id); i regjistrojmë të dyja format.
$subjects = @("repo:${GitHubRepo}:ref:refs/heads/main", "repo:${GitHubRepo}:pull_request")
try {
    $info = Invoke-RestMethod "https://api.github.com/repos/$GitHubRepo"
    $pref = "repo:$($info.owner.login)@$($info.owner.id)/$($info.name)@$($info.id)"
    $subjects += "${pref}:ref:refs/heads/main"
    $subjects += "${pref}:pull_request"
} catch {
    Write-Host "Repo $GitHubRepo nuk u gjet në GitHub (ose është private). Krijojeni, pastaj ekzekutoni skriptën sërish." -ForegroundColor Yellow
}

$n = 0
foreach ($subject in $subjects) {
    $n++
    $have = az ad app federated-credential list --id $appId --query "[?subject=='$subject'].name" -o tsv
    if ($have) { continue }
    $cred = @{ name = "github-$n"; issuer = "https://token.actions.githubusercontent.com"; subject = $subject; audiences = @("api://AzureADTokenExchange") } | ConvertTo-Json -Compress
    $tmp = New-TemporaryFile
    [IO.File]::WriteAllText($tmp.FullName, $cred)
    az ad app federated-credential create --id $appId --parameters "@$($tmp.FullName)" -o none
    Remove-Item $tmp
}

Write-Host "`nGitHub -> Settings -> Secrets and variables -> Actions -> Secrets:" -ForegroundColor Green
Write-Host "AZURE_CLIENT_ID       = $appId"
Write-Host "AZURE_TENANT_ID       = $tenant"
Write-Host "AZURE_SUBSCRIPTION_ID = $sub"
Write-Host "`nNjë po aty, tabi Variables:" -ForegroundColor Green
Write-Host "TF_EMRI               = (emri juaj i vogël, p.sh. ardian)"
Write-Host "STATE_RG              = $StateRg"
Write-Host "STATE_STORAGE         = $StateStorage"
