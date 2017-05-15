resource "azurerm_resource_group" "csra-prod" {
    name = "csra-prod"
    location = "ukwest"
    tags {
      Service = "CSRA"
      Environment = "Prod"
    }
}

resource "azurerm_template_deployment" "csra-prod-webapp" {
  name = "csra-prod-webapp"
  resource_group_name = "${azurerm_resource_group.csra-prod.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../webapp.template.json")}"
  parameters {
    hostname = "csra.noms.dsd.io"
    environment = "Prod"
    ip1 = "${var.ips["office"]}"
    subnet1 = "255.255.255.255"
    ip2 = "${var.ips["quantum"]}"
    subnet2 = "255.255.255.255"
  }
}

# Because the DNS is currently using noms.dsd.io, which is non-prod
# the configuration entry for this is done from the non-prod tf dir

resource "azurerm_dns_cname_record" "cname" {
    name = "csra"
    zone_name = "service.hmpps.dsd.io"
    resource_group_name = "webops-prod"
    ttl = "300"
    record = "csra-prod.azurewebsites.net"
    tags {
      Service = "CSRA"
      Environment = "Prod"
    }
}
