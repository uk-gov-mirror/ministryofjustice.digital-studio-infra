resource "azurerm_resource_group" "csra-poc" {
    name = "csra-poc"
    location = "ukwest"
    tags {
      Service = "CSRA"
      Environment = "PoC"
    }
}

resource "azurerm_template_deployment" "csra-poc-webapp" {
  name = "csra-poc-webapp"
  resource_group_name = "${azurerm_resource_group.csra-poc.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../webapp.template.json")}"
  parameters {
    environment = "PoC"
  }
}
