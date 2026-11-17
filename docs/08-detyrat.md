# 8. Detyrat

Bëjini në **hapi-6-state** (ose në kopje të hapi-5 për ato lokale). Çdo detyrë: ndryshoni kodin → `plan` → `apply` → verifikoni.

## Niveli 1 — Bazë

1. **Tag shtesë.** Shtoni në `locals.tags` çelësin `kursi = "Cloud"` dhe `viti = "2026"`. Sa burime ndryshojnë në `plan`? Pse?
2. **Output i ri.** Shtoni output `key_vault_url` me vlerën `azurerm_key_vault.kv.vault_uri`.
3. **Rajon tjetër.** Provoni `terraform plan -var="location=westeurope"`. Çfarë shihni (`-/+`)? Pse nuk e zbatojmë pa menduar?
4. **Variabël e re.** Shtoni variabël `container_emri` me default `dokumentet` dhe përdoreni te `azurerm_storage_container`.

## Niveli 2 — Praktikë

5. **Container i dytë.** Shtoni container `foto-<emri>`. Çfarë kodi minimal duhet? (Kopjoni `dokumentet`.)
6. **`count` / `for_each`.** Krijoni 3 container-a me një bllok:
   ```hcl
   resource "azurerm_storage_container" "shumë" {
     for_each              = toset(["dokumentet", "foto", "arkiva"])
     name                  = "${each.key}-${var.emri}"
     storage_account_id    = azurerm_storage_account.st.id
     container_access_type = "private"
   }
   ```
7. **Sekret i ri në Key Vault.** Shtoni `azurerm_key_vault_secret` me emrin `MesazhiDemo` dhe vlerë çfarëdo; shihni në Portal.
8. **Drift.** Fshini me dorë në Portal Storage container. Ekzekutoni `plan`. Çfarë ndodh? Ekzekutoni `apply`.
9. **`terraform import`.** Krijoni me dorë (Portal) një Resource Group `rg-importi`. Shkruani `resource` në kod dhe importojeni:
   ```powershell
   terraform import azurerm_resource_group.importi /subscriptions/<sub_id>/resourceGroups/rg-importi
   ```
   Pastaj `plan` duhet të tregojë *No changes*.

## Niveli 3 — Përparuar

10. **Application Insights falas.** Shtoni `azurerm_log_analytics_workspace` + `azurerm_application_insights` dhe lidhni connection string-un te app settings (`APPLICATIONINSIGHTS_CONNECTION_STRING`).
11. **Moduli.** Kaloni burimet e Storage në dosje `modules/storage` me `variables.tf` dhe `outputs.tf`, dhe thirreni me:
    ```hcl
    module "storage" { source = "./modules/storage" ... }
    ```
12. **Mbrojtje nga fshirja.** Te baza SQL shtoni `lifecycle { prevent_destroy = true }` dhe provoni `terraform destroy`. Çfarë ndodh? (Hiqeni përsëri pastaj.)
13. **Mjedise.** Bëni që `plan_sku` të marrë `F1` te `dev.tfvars` dhe `B1` te `prod.tfvars` dhe ekzekutoni `terraform plan -var-file=prod.tfvars`. (Mos e zbatoni B1: kushton.)
14. **Pull request me rishikim.** Punoni me një shok: ai hap PR në repon tuaj, ju rishikoni `plan`-in në Actions dhe e miratoni.

## Pyetje teorike

1. Cili është ndryshimi mes `resource` dhe `data`?
2. Pse nuk bëhet commit `terraform.tfstate`?
3. Çfarë tregon `~`, `+`, `-`, `-/+` te `plan`?
4. Çfarë ndodh nëse e ekzekutoni `terraform apply` dy herë radhazi?
5. Pse përdorim OIDC dhe jo fjalëkalim/çelës në GitHub Secrets?
6. Çfarë është `depends_on` dhe kur duhet?
7. Çfarë ndodh nëse ndryshoni emrin lokal të një burimi në kod (`rg` → `grupi`)?

## Pas detyrave
Gjithmonë: `terraform destroy` (ose lini vetëm çfarë ju duhet). Shih [9. Pastrimi](09-pastrimi-dhe-probleme.md).
