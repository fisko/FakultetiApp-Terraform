# Për profesorin: agjenda e orës dhe këshilla

## Para orës (1-2 ditë më parë)

- Dërgoni studentëve [parakushtet](04-parakushtet.md): subscription i tyre, Terraform, Azure CLI, regjistrimi i shërbimeve.
- Kërkoni që secili të ketë bërë `az login` dhe `terraform version` **para klasës**.
- Çdo student me subscription **Azure for Students** kontrolloni: rajonet e lejuara, kuotën F1 dhe regjistrimin e Microsoft.Sql.
- Burimet e Mësimit 2 (në subscription-in tuaj) nuk lidhen me këtë mësim; studentët punojnë vetëm në subscription-in e tyre.
- Provuar: hapi-5 krijon 17 burime për ~5 min (Key Vault ~2.5 min, `time_sleep` 60 s).

## Agjenda e propozuar (3 orë)

| Koha | Tema | Dokumenti |
|---|---|---|
| 0:00-0:20 | Teoria: pse IaC, imperativ/deklarativ, çfarë është Terraform | 01, 02 |
| 0:20-0:30 | Organizimi i projektit | 03 |
| 0:30-0:45 | Verifikimi i parakushteve | 04 |
| 0:45-1:00 | **Demo e juaja live**: Hapi 1 (init/plan/apply/destroy), eksperimenti idempotence | 05 |
| 1:00-1:15 | Studentët bëjnë Hapin 1 dhe 2 | 05 |
| 1:15-1:30 | Pushim | |
| 1:30-2:15 | Hapat 3, 4, 5 (apply i plotë gjatë të cilit shpjegoni grafin) | 05 |
| 2:15-2:35 | State në Azure, sekretet, rreziqet | 06 |
| 2:35-3:00 | GitHub Actions: plan në PR, apply në merge | 07 |
| Në shtëpi | Detyrat; `terraform destroy` | 08, 09 |

Nëse koha ngushtë: Hapat 3-5 mund të bëhen direkt me `hapi-5-sql`, dhe GitHub Actions kalon për shtëpi.

## Pikat që duhen theksuar

1. **Plan para apply**: gjithmonë lexojeni.
2. `apply` i dytë = *No changes*: ndryshimi nga skriptat `az`.
3. State = kujtesa e Terraform-it; përmban sekrete.
4. Fshirja në Portal kundrejt `terraform plan` (drift).
5. Falas: F1 + SQL free offer; B1 kushton.

## Çka mund të shkojë keq (dhe përgjigjet)

- Emri me shkronja të mëdha/hapësira → validimi jep gabim (mësim i mirë për variablat).
- Rajon pa kapacitet SQL/F1 → ndërroni `location`.
- Subscription i ri pa regjistrim shërbimesh → dok. 4.4.
- OIDC me fork nga llogari tjetër → `oidc-github.ps1` pas krijimit të forkut (njësoj si Mësimi 2).
- Windows PowerShell 5: `Compress-Archive` prish rrugët e zip për Linux App Service → përdorni `tar -a -c -f` (shih hapi 5).

## Pas orës

- Kërkojini studentëve `terraform destroy` dhe fshirjen e `rg-tfstate-*`.
- Kërkoni screenshot të `terraform output` dhe të pull request-it me plan-in në Actions si dëshmi.

## Verifikuar para klasës

Hapi 5 u zbatua me sukses në një subscription test: 17 burime, baza SQL me `useFreeLimit = true`, Key Vault me sekrete, Web App me Managed Identity. Gjithë infrastruktura u fshi pas testit.

## Hapi 7 (opsional, orë shtesë)
Shih [dokumentin 11](11-hapi-7-avancuar.md). Verifikuar me apply/destroy të vërtetë: modul, state në Azure, lock, alarm, buxhet, 6 teste. **Jo të verifikuara:** deploy i aplikacionit (kuota F1 në subscription-in tim) dhe apply real i cilësimeve të fundit (ftps, TLS). Para klasës bëni një provë të plotë.
