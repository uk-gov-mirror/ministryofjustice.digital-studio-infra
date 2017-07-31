resource "azurerm_dns_zone" "service-hmpps" {
    name = "service.hmpps.dsd.io"
    resource_group_name = "${azurerm_resource_group.group.name}"
    tags {
        Service = "WebOps"
        Environment = "Management"
    }
}

output "service.hmpps.dsd.io nameservers" {
    value = ["${azurerm_dns_zone.service-hmpps.name_servers}"]
}
