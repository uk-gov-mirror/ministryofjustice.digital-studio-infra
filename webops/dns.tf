resource "azurerm_dns_zone" "noms" {
    name = "noms.dsd.io"
    resource_group_name = "${azurerm_resource_group.webops.name}"
    tags {
        Service = "WebOps"
        Environment = "Management"
    }
}

resource "azurerm_dns_zone" "hmpps" {
    name = "hmpps.dsd.io"
    resource_group_name = "${azurerm_resource_group.webops.name}"
    tags {
        Service = "WebOps"
        Environment = "Management"
    }
}

resource "azurerm_dns_cname_record" "search" {
    name = "search"
    zone_name = "${azurerm_dns_zone.noms.name}"
    resource_group_name = "${azurerm_resource_group.webops.name}"
    ttl = "300"
    record = "search-noms-api.dsd.io"
}
