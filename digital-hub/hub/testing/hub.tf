resource "azurerm_resource_group" "hub-env-testing" {
    name = "hub-env-testing"
    location = "ukwest"
}

resource "azurerm_public_ip" "hub-env-testing-ip" {
  name                         = "hub-env-testing-ip"
  location                     = "ukwest"
  resource_group_name          = "${azurerm_resource_group.hub-env-testing.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_security_group" "hub-env-testing-nsg" {
  name                = "hub-env-testing-nsg"
  location            = "ukwest"
  resource_group_name = "${azurerm_resource_group.hub-env-testing.name}"


  security_rule {
    name                       = "bounce-dev-allow-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "51.141.40.186"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "bounce-prod-default-allow-ssh"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "51.140.76.188"
    destination_address_prefix = "*"
  }

}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = "${azurerm_resource_group.hub-env-testing.name}"
  virtual_network_name = "${azurerm_virtual_network.hub-env-testing-vnet.name}"
  address_prefix       = "10.0.3.0/24"
}

resource "azurerm_virtual_network" "hub-env-testing-vnet" {
  name                = "hub-env-testing-vnet"
  resource_group_name = "${azurerm_resource_group.hub-env-testing.name}"
  address_space       = ["10.0.3.0/24"]
  location            = "ukwest"
}

resource "azurerm_network_interface" "hub-env-testing-ni" {
  name                      = "hub-env-testing-ni"
  location                  = "ukwest"
  resource_group_name       = "${azurerm_resource_group.hub-env-testing.name}"
  network_security_group_id = "${azurerm_network_security_group.hub-env-testing-nsg.id}"

  ip_configuration {
    name                          = "hub-env-testing-ni-ip"
    subnet_id                     = "${azurerm_subnet.default.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.hub-env-testing-ip.id}"
  }
}


resource "azurerm_virtual_machine" "hub-env-testing-vm" {
  name                  = "hub-env-testing-vm"
  location              = "ukwest"
  resource_group_name   = "${azurerm_resource_group.hub-env-testing.name}"
  network_interface_ids = ["${azurerm_network_interface.hub-env-testing-ni.id}"]
  vm_size               = "Standard_A4m_v2"

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "7.2"
    version   = "latest"
  }

  storage_os_disk {
    name              = "hub-env-testing-vm-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "hub-env-testing-data-disk"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 1
    disk_size_gb      = "150"
  }

  os_profile {
    computer_name  = "hub-env-testing"
    admin_username = "provisioning"
    admin_password = "ThisIsDisabled111!"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/provisioning/.ssh/authorized_keys"
      key_data = "${file("${path.module}/sshkey.pub")}"
    }
  }
}

resource "azurerm_dns_a_record" "hub-env-testing-dns" {
  name = "testing.hub"
  zone_name = "service.hmpps.dsd.io"
  resource_group_name = "webops-prod"
  ttl = "500"
  records = ["51.141.47.59"]
}
