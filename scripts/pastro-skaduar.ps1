<#
.SYNOPSIS
  Pastrim automatik: gjen grupet rg-tf-* që kanë etiketën "skadon" (YYYY-MM-DD) me datë të kaluar dhe i fshin.
  Pa -Fshi vetëm TREGON çfarë do të fshihej (dry-run).

.EXAMPLE
  ./scripts/pastro-skaduar.ps1            # vetëm liston
  ./scripts/pastro-skaduar.ps1 -Fshi      # fshin vërtet
#>
param(
    [switch]$Fshi,
    [string]$Prefix = "rg-tf-",
    [datetime]$Data = (Get-Date)
)
$ErrorActionPreference = "Stop"

if (-not (az account show --query id -o tsv)) { throw "Nuk jeni kyçur. Ekzekutoni: az login" }

$grupet = az group list --query "[?starts_with(name, '$Prefix') && tags.skadon != null].{n:name, s:tags.skadon}" -o json | ConvertFrom-Json
$skaduar = @($grupet | Where-Object {
        $d = [datetime]::MinValue
        [datetime]::TryParseExact($_.s, 'yyyy-MM-dd', $null, 'None', [ref]$d) -and $d.Date -lt $Data.Date
    })

if ($skaduar.Count -eq 0) { Write-Host "Asnjë grup i skaduar (nga $($grupet.Count) me etiketë skadon)." -ForegroundColor Green; return }

foreach ($g in $skaduar) {
    if (-not $Fshi) { Write-Host "DO TË FSHIHEJ: $($g.n) (skadon $($g.s))" -ForegroundColor Yellow; continue }

    Write-Host "Po fshij $($g.n) (skadon $($g.s))" -ForegroundColor Cyan
    # Lock-u CanNotDelete e bllokon fshirjen: e heqim të parin
    az lock list -g $g.n --query "[].id" -o tsv | ForEach-Object { if ($_) { az lock delete --ids $_ } }
    # Buxheti jeton në nivel subscription-i, jo brenda grupit
    $buxhet = "buxhet-" + $g.n.Substring($Prefix.Length)
    az consumption budget delete --budget-name $buxhet 2>$null
    az group delete -n $g.n --yes --no-wait
}
if (-not $Fshi) { Write-Host "`nDry-run. Shtoni -Fshi për ta zbatuar." }
