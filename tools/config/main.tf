variable "app-name" {
    type = "string"
    default = "APPNAME-ENVIRONMENT"
}

variable "tags" {
    type = "map"
    default {
        Environment = "ENVIRONMENT"
    }
}


resource "azurerm_resource_group" "group" {
    name = "${var.app-name}"
    location = "ukwest"
    tags = "${var.tags}"
}

resource "azurerm_storage_account" "storage" {
    name = "STORAGE"
    resource_group_name = "${azurerm_resource_group.group.name}"
    location = "${azurerm_resource_group.group.location}"
    account_tier = "Standard"
    account_replication_type = "RAGRS"
    enable_blob_encryption = true

    tags = "${var.tags}"
}
