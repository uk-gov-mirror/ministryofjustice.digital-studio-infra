resource "azurerm_public_ip" "hub" {
  name                         = "${local.name}-ip"
  location                     = "uksouth"
  resource_group_name          = "${azurerm_resource_group.group.name}"
  public_ip_address_allocation = "static"

  tags = "${local.tags}"
}

resource "azurerm_dns_a_record" "hub" {
  name                = "${local.name}"
  zone_name           = "hmpps.dsd.io"
  resource_group_name = "webops"
  ttl                 = "300"
  records             = ["${azurerm_public_ip.hub.ip_address}"]

  tags = "${local.tags}"
}

resource "azurerm_dns_cname_record" "drupal" {
  name                = "drupal.${local.name}"
  zone_name           = "hmpps.dsd.io"
  resource_group_name = "webops"
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
    name                       = "allow-http-https"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
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

resource "azurerm_network_interface" "hub" {
  name                = "${local.name}-nic"
  location            = "uksouth"
  resource_group_name = "${azurerm_resource_group.group.name}"

  ip_configuration {
    name                          = "default"
    subnet_id                     = "${azurerm_subnet.default.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.hub.id}"
  }

  tags = "${local.tags}"
}

resource "azurerm_virtual_machine" "hub" {
  name                  = "${local.name}-vm"
  location              = "uksouth"
  resource_group_name   = "${azurerm_resource_group.group.name}"
  network_interface_ids = ["${azurerm_network_interface.hub.id}"]
  vm_size               = "Standard_A2_v2"

  boot_diagnostics {
    enabled     = true
    storage_uri = "${azurerm_storage_account.storage.primary_blob_endpoint}"
  }

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${local.name}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = "30"
  }

  storage_data_disk {
    name              = "${local.name}-data"
    create_option     = "Empty"
    managed_disk_type = "Standard_LRS"
    lun               = 0
    disk_size_gb      = "64"
  }

  storage_data_disk {
    name              = "${local.name}-content"
    create_option     = "Empty"
    managed_disk_type = "Standard_LRS"
    lun               = 1
    disk_size_gb      = "256"
  }

  os_profile {
    computer_name  = "${local.name}"
    admin_username = "provisioning"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/provisioning/.ssh/authorized_keys"
      key_data = "${file("${path.module}/sshkey.pub")}"
    }
  }

  tags = "${local.tags}"
}
