variable "app_name" {
  type    = "string"
  default = "webops-jenkins-prod"
}

variable "tags" {
  type = "map"
  default {
    Service     = "WebOps"
    Environment = "Management"
  }
}

resource "azurerm_resource_group" "group" {
  name     = "${var.app_name}"
  location = "ukwest"
  tags     = "${var.tags}"
}


resource "azurerm_storage_account" "storage" {
    name = "${replace(var.app_name, "-", "")}storage"
    resource_group_name = "${azurerm_resource_group.group.name}"
    location = "${azurerm_resource_group.group.location}"
    account_tier = "Standard"
    account_replication_type = "RAGRS"
    enable_blob_encryption = true

    tags = "${var.tags}"
}

resource "azurerm_key_vault" "vault" {
  name                = "${var.app_name}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  location            = "${azurerm_resource_group.group.location}"

  sku {
    name = "standard"
  }

  tenant_id = "${var.azure_tenant_id}"

  access_policy {
    tenant_id          = "${var.azure_tenant_id}"
    object_id          = "${var.azure_webops_group_oid}"
    key_permissions    = []
    secret_permissions = "${var.azure_secret_permissions_all}"
  }

  access_policy {
    tenant_id          = "${var.azure_tenant_id}"
    object_id          = "${var.azure_app_service_oid}"
    key_permissions    = []
    secret_permissions = ["get"]
  }

  access_policy {
      tenant_id = "${var.azure_tenant_id}"
      object_id = "${var.azure_jenkins_sp_oid}"
      key_permissions = []
      secret_permissions = ["set"]
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true

  tags = "${var.tags}"
}

