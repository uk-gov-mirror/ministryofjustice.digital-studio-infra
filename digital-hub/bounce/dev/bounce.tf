resource "azurerm_resource_group" "hub-bounce-dev" {
    name = "hub-bounce-dev"
    location = "ukwest"
}

resource "azurerm_public_ip" "hub-bounce-dev-ip" {
  name                         = "hub-bounce-dev-ip"
  location                     = "ukwest"
  resource_group_name          = "${azurerm_resource_group.hub-bounce-dev.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_security_group" "hub-bounce-dev-nsg" {
  name                = "hub-bounce-dev-nsg"
  location            = "ukwest"
  resource_group_name = "${azurerm_resource_group.hub-bounce-dev.name}"

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
}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = "${azurerm_resource_group.hub-bounce-dev.name}"
  virtual_network_name = "${azurerm_virtual_network.hub-bounce-dev-vnet.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_virtual_network" "hub-bounce-dev-vnet" {
  name                = "hub-bounce-dev-vnet"
  resource_group_name = "${azurerm_resource_group.hub-bounce-dev.name}"
  address_space       = ["10.0.2.0/24"]
  location            = "ukwest"
}


resource "azurerm_network_interface" "hub-bounce-dev-ni" {
  name                = "hub-bounce-dev-ni"
  location            = "ukwest"
  resource_group_name = "${azurerm_resource_group.hub-bounce-dev.name}"

  ip_configuration {
    name                          = "hub-bounce-dev-ni-ip"
    subnet_id                     = "${azurerm_subnet.default.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.hub-bounce-dev-ip.id}"
  }
}

resource "azurerm_virtual_machine" "hub-bounce-dev-vm" {
  name                  = "hub-bounce-dev-vm"
  location              = "ukwest"
  resource_group_name   = "${azurerm_resource_group.hub-bounce-dev.name}"
  network_interface_ids = ["${azurerm_network_interface.hub-bounce-dev-ni.id}"]
  vm_size               = "Basic_A0"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "hub-bounce-dev-vm-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hub-bounce-dev"
    admin_username = "lazzurs"
    admin_password = "ThisIsDisabled111!"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/lazzurs/.ssh/authorized_keys"
      key_data = "ssh-rsa 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"
    }
  }
}
