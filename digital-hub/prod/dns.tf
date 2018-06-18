resource "azurerm_dns_cname_record" "cname_berwyn" {
    name = "bli.prod.admin.hub"
    zone_name = "service.hmpps.dsd.io"
    resource_group_name = "webops-prod"
    ttl = "300"
    record = "prod.admin.hub.service.hmpps.dsd.io"
}

resource "azurerm_dns_cname_record" "cname_wayland" {
    name = "wli.prod.admin.hub"
    zone_name = "service.hmpps.dsd.io"
    resource_group_name = "webops-prod"
    ttl = "300"
    record = "prod.admin.hub.service.hmpps.dsd.io"
}
