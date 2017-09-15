resource "azurerm_dns_zone" "service-hmpps" {
    name = "service.hmpps.dsd.io"
    resource_group_name = "${azurerm_resource_group.group.name}"
    tags {
        Service = "WebOps"
        Environment = "Management"
    }
}

resource "azurerm_dns_ns_record" "nomis-api" {
    name = "nomis-api"
    zone_name = "${azurerm_dns_zone.service-hmpps.name}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    ttl = "300"

    record {
        nsdname = "ns1-07.azure-dns.com."
    }
    record {
        nsdname = "ns2-07.azure-dns.net."
    }
    record {
        nsdname = "ns3-07.azure-dns.org."
    }
    record {
        nsdname = "ns4-07.azure-dns.info."
    }
    tags {
        Service = "WebOps"
        Environment = "Management"
    }
}

output "service.hmpps.dsd.io nameservers" {
    value = ["${azurerm_dns_zone.service-hmpps.name_servers}"]
}
