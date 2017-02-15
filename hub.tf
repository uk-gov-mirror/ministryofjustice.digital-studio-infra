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

resource "heroku_app" "hub-admin-dev" {
  name = "hub-admin-tf-dev"
  region = "eu"
  organization {
    name = "noms-hub"
  }
  config_vars {
    mongo = "${azurerm_template_deployment.digitalhub-template-dev.outputs.dbKey}"
    storage = "${azurerm_template_deployment.digitalhub-template-dev.outputs.storageKey}"
  }
}
