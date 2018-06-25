locals {
  tags = {
    Service     = "Hub"
    Environment = "Stage"
  }
}

resource "azurerm_resource_group" "group" {
  name     = "digital-hub-stage"
  location = "uksouth"
}

resource "azurerm_storage_account" "storage" {
  name                     = "digitalhubstagestorage"
  resource_group_name      = "${azurerm_resource_group.group.name}"
  location                 = "${azurerm_resource_group.group.location}"
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
  enable_blob_encryption   = true

  tags = "${local.tags}"
}
