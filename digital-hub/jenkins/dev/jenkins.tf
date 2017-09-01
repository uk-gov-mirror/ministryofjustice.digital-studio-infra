resource "azurerm_resource_group" "hub-jenkins-dev" {
    name = "hub-jenkins-dev"
    location = "ukwest"
}

resource "azurerm_public_ip" "hub-jenkins-dev-ip" {
  name                         = "hub-jenkins-dev-ip"
  location                     = "ukwest"
  resource_group_name          = "${azurerm_resource_group.hub-jenkins-dev.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_security_group" "hub-jenkins-dev-nsg" {
  name                = "hub-jenkins-dev-nsg"
  location            = "ukwest"
  resource_group_name = "${azurerm_resource_group.hub-jenkins-dev.name}"

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
  resource_group_name  = "${azurerm_resource_group.hub-jenkins-dev.name}"
  virtual_network_name = "${azurerm_virtual_network.hub-jenkins-dev-vnet.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_virtual_network" "hub-jenkins-dev-vnet" {
  name                = "hub-jenkins-dev-vnet"
  resource_group_name = "${azurerm_resource_group.hub-jenkins-dev.name}"
  address_space       = ["10.0.2.0/24"]
  location            = "ukwest"
}


resource "azurerm_network_interface" "hub-jenkins-dev-ni" {
  name                      = "hub-jenkins-dev-ni"
  location                  = "ukwest"
  resource_group_name       = "${azurerm_resource_group.hub-jenkins-dev.name}"
  network_security_group_id = "${azurerm_network_security_group.hub-jenkins-dev-nsg.id}"

  ip_configuration {
    name                          = "hub-jenkins-dev-ni-ip"
    subnet_id                     = "${azurerm_subnet.default.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.hub-jenkins-dev-ip.id}"
  }
}

resource "azurerm_virtual_machine" "hub-jenkins-dev-vm" {
  name                  = "hub-jenkins-dev-vm"
  location              = "ukwest"
  resource_group_name   = "${azurerm_resource_group.hub-jenkins-dev.name}"
  network_interface_ids = ["${azurerm_network_interface.hub-jenkins-dev-ni.id}"]
  vm_size               = "Basic_A3"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "hub-jenkins-dev-vm-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hub-jenkins-dev"
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
