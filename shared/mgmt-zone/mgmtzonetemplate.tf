# The purpose of this terraform runbook is to stand up the following resources:
#   1) Management Zone Resource Group
#   2) Keyvault with secrets preseeded - Administrative details
#   3) Management vnet
#   4) management Subnet
#   5) ssh jump box
#   6) CI server (vm only - managed disks)
#   7) Application Gateway with SSL certificate deployed - Wont actually do this natively - need to call the rm template which is a bit non-ideal
#   8) DNS Entry for CI server (This will actually point at the cname of the applicatoin gateway).
#   9) basic NSGs
#
#
# The details above have been determined by evaluating the configuration in place for previous IAAS based projects where the 
# application resource group and the management infrastructure resoure groups are distinct. 
# Based on this it was felt that we could provide this template as a basis for your own management zone, setting up the basic structure
# which can be customized as required.


terraform {
    required_version = ">= 0.9.2"
    backend "azure" {
        resource_group_name = "changeme"
        storage_account_name = "changeme"
        container_name = "terraform"
        key = "notm-dev.terraform.tfstate"
        arm_subscription_id = "changeme"
        arm_tenant_id = "changeme"
    }
}

variable "sshprivkey" {
    type = "string"
    default = ""
}
variable "env-name" {
    type = "string"
    default = "changeme"
}
variable "rg-name" {
    type = "string"
    default = "changeme"
}
variable "mgmt-vnet-space"{
    type = "string"
    default = "10.0.0.0/16"
}
variable "ci-server-name" {
    type = "string"
    default = "changeme"
}
variable "jmp-server-name" {
    type = "string"
    default = "changeme"
}
variable "tags" {
    type = "map"
    default {
        Service = "changeme"
        Environment = "changeme"
    }
}


resource "random_id" "session-secret" {
    byte_length = 20
}
resource "random_id" "ci-admin-password" {
    byte_length = 16
}
resource "random_id" "jmp-admin-password" {
    byte_length = 16
}

#The default location in this template is ukwest. Please check that this is the expected location for your service.

resource "azurerm_resource_group" "mgmt" {
    name = "${var.rg-name}"
    location = "ukwest"
    tags = "${var.tags}"
}

#you may not require the virtual network to be specified if you already have this provisioned.

resource "azurerm_virtual_network" "vnet" {
  name                = "mgmt-vnet"
  address_space       = ["${var.mgmt-vnet-space}"]
  location            = "ukwest"
  resource_group_name = "${azurerm_resource_group.mgmt.name}"
}

resource "azurerm_key_vault" "vault" {
    name = "${var.app-name}"
    resource_group_name = "${azurerm_resource_group.mgmt.name}"
    location = "${azurerm_resource_group.mgmt.location}"
    sku {
        name = "standard"
    }
    tenant_id = "${var.azure_tenant_id}"

    access_policy {
        tenant_id = "${var.azure_tenant_id}"
        object_id = "${var.azure_vault_group_oid}"
        key_permissions = ["all"]
        secret_permissions = ["all"]
    }
    access_policy {
        tenant_id = "${var.azure_tenant_id}"
        object_id = "${var.azure_app_service_oid}"
        key_permissions = []
        secret_permissions = ["get"]
    }
    access_policy {
        object_id = "${var.azure_tfuser_oid}"
        tenant_id = "${var.azure_tenant_id}"
        key_permissions = ["get"]
        secret_permissions = ["get"]
    }

    enabled_for_deployment = true
    enabled_for_disk_encryption = true
    enabled_for_template_deployment = true

    tags = "${var.tags}"
}


resource "azurerm_resource_group" "mgmt" {
  name     = "changeme"
  location = "ukwest"
}

resource "azurerm_subnet" "mgmt-subnet" {
  name                 = "mgmt-subnet"
  resource_group_name  = "${azurerm_resource_group.mgmt.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_subnet" "apgw-subnet" {
  name                 = "apgw-subnet"
  resource_group_name  = "${azurerm_resource_group.mgmt.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.0.3.0/24"
}

resource "azurerm_network_interface" "ci-nic" {
  name                = "ci-nic"
  location            = "ukwest"
  resource_group_name = "${azurerm_resource_group.mgmt.name}"

  ip_configuration {
    name                          = "ci-nic-config"
    subnet_id                     = "${azurerm_subnet.mgmt-subnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = ""
  }
}

resource "azurerm_managed_disk" "ci-data-disk" {
  name                 = "ci-data-disk"
  location             = "ukwest"
  resource_group_name  = "${azurerm_resource_group.mgmt.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

resource "azurerm_virtual_machine" "ci" {
  name                  = "${var.ci-server-name}"
  location              = "ukwest"
  resource_group_name   = "${azurerm_resource_group.mgmt.name}"
  network_interface_ids = ["${azurerm_network_interface.ci-nic.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.ci-server-name}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "datadisk_new"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "1023"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.ci-data-disk.name}"
    managed_disk_id = "${azurerm_managed_disk.ci-data-disk.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.ci-data-disk.disk_size_gb}"
  }

  os_profile {
    computer_name  = "${var.ci-server-name}"
    admin_username = "ciadmin"
    admin_password = "${var.ci-admin-password}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
  }

  tags {
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
        role = "other"
  }
}

resource "azurerm_public_ip" "jump" {
  name                         = "jmpPublicIp1"
  location                     = "ukwest"
  resource_group_name          = "${azurerm_resource_group.mgmt.name}"
  public_ip_address_allocation = "static"

  tags {
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
  }
}

resource "azurerm_network_interface" "jump-nic" {
  name                = "jump-nic"
  location            = "ukwest"
  resource_group_name = "${azurerm_resource_group.mgmt.name}"

  ip_configuration {
    name                          = "jump-nic-config"
    subnet_id                     = "${azurerm_subnet.mgmt-subnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = 
  }
}

resource "azurerm_managed_disk" "jump-data-disk" {
  name                 = "jump-data-disk"
  location             = "ukwest"
  resource_group_name  = "${azurerm_resource_group.mgmt.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

resource "azurerm_virtual_machine" "jump" {
  name                  = "${var.ci-server-name}"
  location              = "ukwest"
  resource_group_name   = "${azurerm_resource_group.mgmt.name}"
  network_interface_ids = ["${azurerm_network_interface.ci-nic.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.jump-server-name}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "datadisk_new"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "1023"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.jump-data-disk.name}"
    managed_disk_id = "${azurerm_managed_disk.jump-data-disk.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.jump-data-disk.disk_size_gb}"
  }

  os_profile {
    computer_name  = "${var.jump-server-name}"
    admin_username = "jmpadmin"
    admin_password = "${var.jmp-admin-password}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
  }

  tags {
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
        role = "other"
  }
}

resource "azurerm_template_deployment" "management-appgw" {
    name = "appgwdeployment"
    resource_group_name = "${azurerm_resource_group.mgmt.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/mgmt-appgw.template.json")}"

    parameters {
        subnetPrefix = "${azurerm_subnet.appGatewaySubnet.address_prefix}"
        applicationGatewaySize = "WAF_Medium"
        capacity = "2"
        backendIpAddress1 = "${azurerm_network_interface.ci-nic.private_ip_address}"
        wafEnabled = true
        wafRuleSetType = "OWASP"
        wafRuleSetVersion = "3.0"
        wafMode = "Prevention"
        appGWName = "${var.tags["Service"]}"
        virtualNetworkName: "${azurerm_virtual_network.mgmt-vnet.name}"
        subnetName = "${azurerm_subnet.appGatewaySubnet.name}"
        vnetID = "${azurerm_virtual_network.mgmt-vnet.id}"
        keyVaultId = "${azurerm_key_vault.vault.id}"
        keyVaultCertName = "changeDOTthis"
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
        role = "other"
    }
    output "appgwcname" {
      value = "${azurerm_template_deployment.management-appgw.outputs["appgwcname"]}"
    }

resource "azurerm_dns_cname_record" "cname" {
    name = "ci"
    zone_name = "${var.tags["Service"]}.hmpps.dsd.io"
    resource_group_name = "changeme"
    ttl = "300"
    record = "${azurerm_template_deployment.management-appgw.output.appgwcname}"
    tags = "${var.tags}"
}
