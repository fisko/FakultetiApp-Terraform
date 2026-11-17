# 1. Pse Terraform?

## Si i krijuam burimet deri tani

Në Mësimin 2 klikuam në Portal dhe ekzekutuam skripta `az`. Funksionon, por shihni vetë problemet:

| Problem | Shembull nga klasa |
|---|---|
| **Gabime njerëzore** | Dikush futi çelës të gabuar të Storage; tjetri futi `AZURE_CLIENT_ID` të gabuar |
| **Nuk përsëritet** | "Si e krijova atë Key Vault?" Faton i fshiu burimet dhe duhej t'i bënte të gjitha nga e para |
| **Nuk dihet gjendja** | Çfarë ekziston tani në Azure? Çfarë ndryshoi dhe kush e ndryshoi? |
| **Skripta është "si të bëj"** | `az ... create` dështon nëse burimi ekziston; duhet të shkruash vetë kontrollet |
| **Pastrimi është i lodhshëm** | Duhet të kujtohesh çfarë krijove që ta fshish (dhe çfarë kushton) |
| **Nuk ka histori** | Në Portal nuk ka "commit" ose "pull request" |

## Zgjidhja: Infrastructure as Code (IaC)

**Infrastructure as Code** = infrastrukturën e përshkruani në **skedarë teksti** (kod), ashtu si shkruani aplikacionin.
Pastaj një mjet i lexon dhe e krijon në Azure.

Përfitimet:

1. **Përsëritshmëri** - i njëjti kod krijon të njëjtën gjë 1 herë ose 100 herë.
2. **Version control** - kodi është në Git: shihet historia, kush ndryshoi çfarë, mund të kthehesh mbrapa.
3. **Rishikim** - infrastruktura kalon nëpër *pull request* si çdo kod tjetër.
4. **Dokumentim i gjallë** - kodi *është* dokumentimi; asnjëherë i vjetruar.
5. **Fshirje e pastër** - `terraform destroy` fshin saktësisht çfarë krijoi.
6. **Automatizim** - GitHub Actions e zbaton pa asnjë klikim.

## Imperativ kundrejt deklarativ

Kjo është ideja më e rëndësishme e mësimit.

| | Imperativ (skriptat tona `az`) | Deklarativ (Terraform) |
|---|---|---|
| Çfarë shkruani | **Hapat**: "krijo grupin, pastaj krijo planin..." | **Gjendjen e dëshiruar**: "dua një grup, një plan, një web app" |
| Nëse e ekzekutoni 2 herë | Gabim "ekziston tashmë", ose dublikon | Asgjë nuk ndryshon (nuk ka çfarë) |
| Ndryshim (p.sh. F1 → B1) | Shkruani komandë të re `update` | Ndryshoni një rresht dhe Terraform e llogarit ndryshimin |
| Fshirje | Shkruani komandat e fshirjes | `terraform destroy` |

Analogji: imperativ është **recetë hap pas hapi**; deklarativ është **porosia në restorant** ("dua një pica margarita"): s'ju intereson si e gatuan kuzhinieri.

## Pse pikërisht Terraform (dhe jo Bicep, ARM, Pulumi)?

| Mjeti | Shënim |
|---|---|
| **Terraform** (HashiCorp) | Standardi i industrisë, **funksionon me çdo cloud** (Azure, AWS, Google, GitHub...), komunitet i madh, gjuhë e thjeshtë (HCL) |
| Bicep / ARM | Vetëm Azure; shumë i mirë nëse punoni vetëm me Azure |
| Pulumi | Përdor gjuhë programimi (C#, Python); më i ri |
| Skripta `az`/PowerShell | Imperativ; mirë për demo të shpejta, jo për menaxhim të gjatë |

Për studentët e informatikës: njohja e Terraform është **aftësi e kërkuar në punë** (DevOps, cloud engineer), dhe ajo që mësoni vlen edhe për AWS/GCP.

## Çfarë NUK bën Terraform

- Nuk e **ndërton** aplikacionin; vetëm krijon infrastrukturën. Kodin e deploy-ojmë me `deploy.yml` nga Mësimi 2.
- Nuk është magji: nëse shkruani konfigurim të gabuar, krijon infrastrukturë të gabuar (shpejt dhe me siguri!).
- Nuk i fsheh sekretet vetë: **state** përmban vlerat (shih [dokumentin 6](06-state-dhe-sekretet.md)).

Vazhdoni: [2. Çfarë është Terraform](02-cfare-eshte-terraform.md)
