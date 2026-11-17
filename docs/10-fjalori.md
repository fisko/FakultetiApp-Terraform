# 10. Fjalori

| Termi | Shpjegim |
|---|---|
| **IaC** (Infrastructure as Code) | Infrastruktura e përshkruar në skedarë kodi |
| **Terraform** | Mjeti që e lexon kodin dhe krijon burimet |
| **HCL** | Gjuha e skedarëve `.tf` |
| **Provider** | Plugin për një shërbim (azurerm = Azure) |
| **Resource** | Burim që Terraform e krijon/menaxhon |
| **Data source** | Lexim i diçkaje ekzistuese |
| **Variable** | Hyrje e konfigurimit (`var.emri`) |
| **Local** | Vlerë e llogaritur brenda kodit (`local.tags`) |
| **Output** | Vlerë e shfaqur në fund |
| **State** | Skedari ku Terraform ruan çfarë ka krijuar |
| **Backend** | Vendi ku ruhet state (lokal ose Azure Storage) |
| **Lock** | Mbyllje e state që dy `apply` të mos përplasen |
| **Plan** | Parashikimi i ndryshimeve pa i bërë |
| **Apply** | Zbatimi i ndryshimeve |
| **Destroy** | Fshirja e gjithçkaje të menaxhuar |
| **Drift** | Dallimi mes kodit/state dhe asaj që ekziston realisht (ndryshime me dorë) |
| **Idempotent** | Ekzekutimi i përsëritur nuk ndryshon rezultatin |
| **Deklarativ / Imperativ** | "Çfarë dua" / "Çfarë hapash të bëj" |
| **Module** | Dosje me burime të ripërdorshme |
| **Import** | Marrja e një burimi ekzistues nën menaxhimin e Terraform |
| **Lock file** | `.terraform.lock.hcl`, versionet e provider-ave |
| **azapi** | Provider që flet drejtpërdrejt me API-n e Azure (për veçori që azurerm s'i ka) |
| **Resource Group** | Kontejner logjik i burimeve në Azure |
| **App Service Plan** | Serveri (kapaciteti) ku punon Web App |
| **Managed Identity** | Identitet i aplikacionit në Azure, pa fjalëkalim |
| **RBAC** | Kontroll aksesi me role (Secrets User, Contributor, Owner...) |
| **Key Vault reference** | `@Microsoft.KeyVault(...)` në app setting: vlera lexohet nga Key Vault |
| **OIDC** | GitHub dhe Azure besojnë njëri-tjetrin me token afatshkurtër, pa fjalëkalim |
| **Federated credential** | Rregulli në Azure: "beso këtë repo/branch" |
| **CI/CD** | Ndërtim dhe zbatim automatik pas çdo ndryshimi në Git |
| **Free offer (SQL)** | Baza falas e Azure SQL me kufi mujor |
| **Modul** | Folder `.tf` i ripërdorshëm me hyrje, logjikë dhe dalje |
| **Drift** | Azure ndryshoi jashtë Terraform; kodi dhe realiteti nuk përputhen |
| **Import** | Sjellja e një burimi ekzistues nën menaxhimin e Terraform |
| **Lock** | Mbrojtje e Azure që bllokon fshirjen e burimit |
| **Mock provider** | Provider i rremë për `terraform test` pa Azure |
| **Checkov** | Mjet që skanon kodin Terraform për probleme sigurie |
| **Application Insights** | Shërbim monitorimi i aplikacionit |
| **Mjedis (environment)** | Kopje e infrastrukturës për një qëllim: `dev` (provë) ose `prod` (real) |
| **`tfvars`** | Skedar me vlera të variablave për një mjedis (`-var-file`) |
| **Workspace** | Njësi e state-it në Terraform Cloud; zakonisht një për mjedis |
| **Terraform Cloud (HCP)** | Shërbim i HashiCorp që ekzekuton plan/apply dhe ruan state |
| **GitHub Environment** | Cilësim në GitHub që kërkon miratim para se një workflow të prekë `prod` |
| **`skadon`** | Tag me datën pas së cilës burimi pastrohet automatikisht |
