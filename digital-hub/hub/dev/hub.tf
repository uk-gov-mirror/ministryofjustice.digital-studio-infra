resource "azurerm_resource_group" "hub-env-dev" {
    name = "hub-env-dev"
    location = "ukwest"
}

resource "azurerm_public_ip" "hub-env-dev-ip" {
  name                         = "hub-env-dev-ip"
  location                     = "ukwest"
  resource_group_name          = "${azurerm_resource_group.hub-env-dev.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_security_group" "hub-env-dev-nsg" {
  name                = "hub-env-dev-nsg"
  location            = "ukwest"
  resource_group_name = "${azurerm_resource_group.hub-env-dev.name}"

  security_rule {
    name                       = "default-allow-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-https"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = "${azurerm_resource_group.hub-env-dev.name}"
  virtual_network_name = "${azurerm_virtual_network.hub-env-dev-vnet.name}"
  address_prefix       = "10.0.3.0/24"
}

resource "azurerm_virtual_network" "hub-env-dev-vnet" {
  name                = "hub-env-dev-vnet"
  resource_group_name = "${azurerm_resource_group.hub-env-dev.name}"
  address_space       = ["10.0.3.0/24"]
  location            = "ukwest"
}

resource "azurerm_network_interface" "hub-env-dev-ni" {
  name                = "hub-env-dev-ni"
  location            = "ukwest"
  resource_group_name = "${azurerm_resource_group.hub-env-dev.name}"

  ip_configuration {
    name                          = "hub-env-dev-ni-ip"
    subnet_id                     = "${azurerm_subnet.default.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.hub-env-dev-ip.id}"
  }
}


resource "azurerm_virtual_machine" "hub-env-dev-vm" {
  name                  = "hub-env-dev-vm"
  location              = "ukwest"
  resource_group_name   = "${azurerm_resource_group.hub-env-dev.name}"
  network_interface_ids = ["${azurerm_network_interface.hub-env-dev-ni.id}"]
  vm_size               = "Basic_A3"

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "7.3"
    version   = "latest"
  }

  storage_os_disk {
    name              = "hub-env-dev-vm-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hub-env-dev"
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
