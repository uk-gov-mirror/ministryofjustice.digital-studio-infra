provider "azurerm" {
  # NOMS Digital Studio Dev & Test Environments
  subscription_id = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
  # client_id = "..." use ARM_CLIENT_ID env var
  # client_secret = "..." use ARM_CLIENT_SECRET env var
  tenant_id = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
}

resource "azurerm_resource_group" "digitalhub-dev" {
    name = "tf_digitalhub_dev"
    location = "ukwest"
    tags {
      Service = "Digital Hub"
      Environment = "dev"
    }
}

resource "azurerm_template_deployment" "digitalhub-template-dev" {
  name = "tf_digitalhub_template_dev"
  resource_group_name = "${azurerm_resource_group.digitalhub-dev.name}"
  deployment_mode = "Incremental"
  template_body = "${file("templates/digitalhub.json")}"
  parameters {
    digitalhub_environment = "tfdev"
  }
}

resource "azurerm_storage_container" "digitalhub-container-content-dev" {
  depends_on = ["azurerm_template_deployment.digitalhub-template-dev"]
  name = "content-items"
  resource_group_name = "${azurerm_resource_group.digitalhub-dev.name}"
  storage_account_name = "digitalhubtfdev"
  container_access_type = "container"
}

output "db" {
  value = "${azurerm_template_deployment.digitalhub-template-dev.outputs.dbKey}"
}
output "storage" {
  value = "${azurerm_template_deployment.digitalhub-template-dev.outputs.storageKey}"
}
