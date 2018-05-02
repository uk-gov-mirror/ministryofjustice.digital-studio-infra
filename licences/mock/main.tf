
resource "random_id" "sql-nomis-batchload-password" {
  byte_length = 32
}

resource "azurerm_resource_group" "group" {
  name     = "${var.app-name}"
  location = "ukwest"
  tags     = "${var.tags}"
}

resource "azurerm_storage_account" "storage" {
  name                     = "${replace(var.app-name, "-", "")}storage"
  resource_group_name      = "${azurerm_resource_group.group.name}"
  location                 = "${azurerm_resource_group.group.location}"
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
  enable_blob_encryption   = true

  tags = "${var.tags}"
}

resource "azurerm_storage_container" "logs" {
  name                  = "web-logs"
  resource_group_name   = "${azurerm_resource_group.group.name}"
  storage_account_name  = "${azurerm_storage_account.storage.name}"
  container_access_type = "private"
}

resource "azurerm_key_vault" "vault" {
  name                = "${var.app-name}"
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
    object_id          = "${var.azure_licences_group_oid}"
    key_permissions    = []
    secret_permissions = "${var.azure_secret_permissions_all}"
  }

  access_policy {
    tenant_id = "${var.azure_tenant_id}"
    object_id = "${var.azure_jenkins_sp_oid}"
    key_permissions = []
    secret_permissions = ["set"]
  }

  access_policy {
    tenant_id          = "${var.azure_tenant_id}"
    object_id          = "${var.azure_app_service_oid}"
    key_permissions    = []
    secret_permissions = ["get"]
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true

  tags = "${var.tags}"
}


module "sql-nomis-batchload" {
  source              = "../../shared/modules/azure-sql"
  name                = "nomis-batchload-${var.app-name}"
  resource_group      = "${azurerm_resource_group.group.name}"
  location            = "${azurerm_resource_group.group.location}"
  administrator_login = "licences"

  firewall_rules = [
    {
      label = "Open to the world"
      start = "0.0.0.0"
      end   = "255.255.255.255"
    },
  ]

  audit_storage_account = "${azurerm_storage_account.storage.name}"
  edition               = "Basic"
  collation             = "SQL_Latin1_General_CP1_CI_AS"
  tags                  = "${var.tags}"

  db_users = {
    app = "${random_id.sql-nomis-batchload-password.b64}"
  }

  setup_queries = [
    "ALTER ROLE db_datareader ADD MEMBER app",
    "ALTER ROLE db_datawriter ADD MEMBER app",
  ]
}

data "external" "sas-url" {
  program = ["python3", "../../tools/container-sas-url-cli-auth.py"]

  query {
    subscription_id = "${var.azure_subscription_id}"
    tenant_id       = "${var.azure_tenant_id}"
    resource_group  = "${azurerm_resource_group.group.name}"
    storage_account = "${azurerm_storage_account.storage.name}"
    container       = "web-logs"
    permissions     = "rwdl"
    start_date      = "2017-05-15T00:00:00Z"
    end_date        = "2217-05-15T00:00:00Z"
  }
}

