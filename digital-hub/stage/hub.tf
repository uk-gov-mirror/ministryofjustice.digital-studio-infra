resource "azurerm_dns_a_record" "hub" {
  name                = "pfs-${local.name}"
  zone_name           = "hmpps.dsd.io"
  resource_group_name = "webops-shared-dns-devtest"
  ttl                 = "300"
  records             = ["51.140.117.241"]

  tags = "${local.tags}"
}

resource "azurerm_dns_cname_record" "content" {
  name                = "content.pfs-${local.name}"
  zone_name           = "hmpps.dsd.io"
  resource_group_name = "webops-shared-dns-devtest"
  ttl                 = "300"
  record              = "${azurerm_dns_a_record.hub.name}.${azurerm_dns_a_record.hub.zone_name}"

  tags = "${local.tags}"
}

resource "azurerm_dns_cname_record" "analytics" {
  name                = "analytics.pfs-${local.name}"
  zone_name           = "hmpps.dsd.io"
  resource_group_name = "webops-shared-dns-devtest"
  ttl                 = "300"
  record              = "${azurerm_dns_a_record.hub.name}.${azurerm_dns_a_record.hub.zone_name}"

  tags = "${local.tags}"
}

locals {
  hub_bounce_prod_ip = "51.140.76.188"
}

resource "azurerm_network_security_group" "hub" {
  name                = "${local.name}-hub-nsg"
  location            = "uksouth"
  resource_group_name = "${azurerm_resource_group.group.name}"

  security_rule {
    name                       = "ssh-from-bounce"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${local.hub_bounce_prod_ip}"
    destination_address_prefix = "*"
  }

  security_rule {
    name      = "allow-http-https"
    priority  = 1100
    direction = "Inbound"
    access    = "Allow"
    protocol  = "TCP"

    destination_port_ranges    = ["80", "443"]
    destination_address_prefix = "*"
    source_port_range          = "*"
    source_address_prefix      = "*"
  }

  security_rule {
    name                       = "deny-everything-else"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = "${local.tags}"
}

resource "azurerm_virtual_network" "hub" {
  name                = "${local.name}-vnet"
  resource_group_name = "${azurerm_resource_group.group.name}"
  address_space       = ["10.0.1.0/28"]
  location            = "uksouth"

  tags = "${local.tags}"
}

resource "azurerm_subnet" "default" {
  name                      = "default"
  resource_group_name       = "${azurerm_resource_group.group.name}"
  virtual_network_name      = "${azurerm_virtual_network.hub.name}"
  address_prefix            = "10.0.1.0/28"
  network_security_group_id = "${azurerm_network_security_group.hub.id}"
}
