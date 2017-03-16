terraform {
    required_version = ">= 0.9.0"
    backend "azure" {
        resource_group_name = "webops"
        storage_account_name = "nomsstudiowebops"
        container_name = "terraform"
        key = "csra-poc.terraform.tfstate"
        arm_subscription_id = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
        arm_tenant_id = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
    }
}


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
    hostname = "${azurerm_dns_cname_record.csra-poc.name}.${azurerm_dns_cname_record.csra-poc.zone_name}"
    environment = "PoC"
  }
}

resource "azurerm_dns_cname_record" "csra-poc" {
    name = "csra-poc"
    zone_name = "noms.dsd.io"
    resource_group_name = "webops"
    ttl = "300"
    record = "csra-poc.azurewebsites.net"
    tags {
        Service = "CSRA"
        Environment = "PoC"
    }
}

# The "production" site currently uses this non-production DNS entry
# which can only be configured via the non-prod subscription
resource "azurerm_dns_cname_record" "csra-prod" {
    name = "csra"
    zone_name = "noms.dsd.io"
    resource_group_name = "webops"
    ttl = "300"
    record = "csra-prod.azurewebsites.net"
    tags {
        Service = "CSRA"
        Environment = "Prod"
    }
}
