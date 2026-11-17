# Testet e Terraform (terraform test). Punojnë PA Azure: përdorin "mock_provider", pra asgjë nuk krijohet.
# Ekzekutimi:  terraform init -backend=false   pastaj   terraform test

mock_provider "azurerm" {
  # Key Vault ka nevojë për tenant_id të vlefshëm (GUID); mock-u kthen tekst të rastësishëm
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "00000000-0000-0000-0000-000000000000"
      object_id       = "00000000-0000-0000-0000-000000000001"
      subscription_id = "00000000-0000-0000-0000-000000000002"
    }
  }
}
mock_provider "azapi" {}

variables {
  subscription_id = "00000000-0000-0000-0000-000000000002"
  emri            = "test"
}

run "emrat_dhe_etiketat" {
  command = plan

  assert {
    condition     = azurerm_resource_group.rg.name == "rg-tf-test"
    error_message = "Emri i grupit duhet të jetë rg-tf-<emri>."
  }

  assert {
    condition     = azurerm_resource_group.rg.tags["krijuar"] == "terraform"
    error_message = "Çdo burim duhet të ketë etiketën krijuar=terraform."
  }
}

run "mjedisi_dev_ndryshon_emrat" {
  command = plan

  variables {
    mjedisi = "dev"
    skadon  = "2030-01-01"
  }

  assert {
    condition     = azurerm_resource_group.rg.name == "rg-tf-testdev"
    error_message = "Me mjedisi=dev grupi duhet të quhet rg-tf-<emri>dev."
  }

  assert {
    condition     = azurerm_resource_group.rg.tags["skadon"] == "2030-01-01" && azurerm_resource_group.rg.tags["mjedisi"] == "dev"
    error_message = "Etiketat mjedisi dhe skadon duhet të vihen."
  }
}

run "baza_eshte_falas" {
  command = plan

  assert {
    condition     = azapi_resource.db.body.properties.useFreeLimit == true
    error_message = "Baza SQL duhet të përdorë offertën falas (useFreeLimit = true)."
  }
}

run "key_vault_ka_rbac" {
  command = plan

  assert {
    condition     = azurerm_key_vault.kv.rbac_authorization_enabled == true
    error_message = "Key Vault duhet të përdorë RBAC."
  }
}

run "emri_i_pavlefshem_refuzohet" {
  command = plan

  variables {
    emri = "Emri Me Hapesira"
  }

  expect_failures = [var.emri]
}

run "pa_email_nuk_ka_alarme" {
  command = plan

  assert {
    condition     = length(azurerm_monitor_metric_alert.http5xx) == 0
    error_message = "Pa alert_email nuk duhet të krijohet alarm."
  }
}

run "me_email_krijohet_alarmi" {
  command = plan

  variables {
    alert_email = "student@example.com"
  }

  assert {
    condition     = length(azurerm_monitor_metric_alert.http5xx) == 1
    error_message = "Me alert_email duhet të krijohet alarmi."
  }
}
