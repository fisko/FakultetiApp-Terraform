<#
.SYNOPSIS
  Krijon vendin ku ruhet "state" i Terraform-it: Resource Group + Storage account + container "tfstate".
  Ky është i vetmi burim që krijohet me dorë (me CLI), sepse Terraform ka nevojë për të para se të nisë.

.EXAMPLE
  ./scripts/krijo-state.ps1 -Emri ardian
#>
param(
    [Parameter(Mandatory)][string]$Emri,           # emri juaj i vogël, p.sh. ardian
    [string]$Location = "swedencentral"
)
$ErrorActionPreference = "Stop"

$emri = $Emri.ToLower() -replace '[^a-z0-9]', ''
$sub  = az account show --query id -o tsv
if (-not $sub) { throw "Nuk jeni kyçur. Ekzekutoni: az login" }

$rg = "rg-tfstate-$emri"
# Emri i storage duhet të jetë unik; marrim 5 shkronja nga ID e subscription-it (gjithmonë të njëjta për ju)
$suffix = ($sub -replace '-', '').Substring(0, 5)
$st = "sttf$emri$suffix"

Write-Host "1) Grupi $rg" -ForegroundColor Cyan
az group create -n $rg -l $Location -o none

Write-Host "2) Storage account $st" -ForegroundColor Cyan
az storage account create -n $st -g $rg -l $Location --sku Standard_LRS --min-tls-version TLS1_2 `
    --allow-blob-public-access false --allow-shared-key-access false -o none

Write-Host "3) Leja për ju (Storage Blob Data Contributor)" -ForegroundColor Cyan
$me = az ad signed-in-user show --query id -o tsv
$scope = az storage account show -n $st -g $rg --query id -o tsv
az role assignment create --assignee-object-id $me --assignee-principal-type User `
    --role "Storage Blob Data Contributor" --scope $scope -o none

Write-Host "4) Container tfstate (prisni ~30 sek që leja të aktivizohet)" -ForegroundColor Cyan
Start-Sleep -Seconds 30
$ok = $false
foreach ($i in 1..6) {
    az storage container create -n tfstate --account-name $st --auth-mode login -o none 2>$null
    if ($LASTEXITCODE -eq 0) { $ok = $true; break }
    Write-Host "   po provoj sërish ($i/6)..."; Start-Sleep -Seconds 20
}
if (-not $ok) { throw "Container nuk u krijua. Provoni përsëri skriptën pas 1-2 minutash." }

Write-Host "`nGati. Për 'terraform init' përdorni këto vlera:" -ForegroundColor Green
Write-Host "  resource_group_name  = $rg"
Write-Host "  storage_account_name = $st"
Write-Host "  container_name       = tfstate"
Write-Host "`nKomanda e plotë:"
Write-Host "terraform init -backend-config=`"resource_group_name=$rg`" -backend-config=`"storage_account_name=$st`" -backend-config=`"subscription_id=$sub`""
