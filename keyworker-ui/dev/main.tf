variable "env-name" {
    type = "string"
    default = "keyworker-ui-dev"
}

variable "tags" {
    type = "map"
    default {
        Service = "keyworker-ui"
        Environment = "Dev"
    }
}

resource "random_id" "session-secret" {
  byte_length = 40
}

resource "azurerm_app_service_plan" "keyworker-ui" {
  name                = "${var.env-name}"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"

  sku {
    tier     = "Standard"
    size     = "S1"
    capacity = 1
  }
}

resource "azurerm_resource_group" "group" {
  name     = "${var.env-name}"
  location = "ukwest"
  tags     = "${var.tags}"
}

resource "azurerm_app_service" "keyworker-ui" {
  name                = "${var.env-name}"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  app_service_plan_id = "${azurerm_app_service_plan.keyworker-ui.id}"

  app_settings {
    WEBSITE_NODE_DEFAULT_VERSION = "8.4.0"
    NODE_ENV       = "dev"
    SESSION_SECRET = "${random_id.session-secret.b64}"
  }
}

data "external" "vault" {
  program = ["python3", "../../tools/keyvault-data-cli-auth.py"]

  query {
    vault = "${azurerm_key_vault.vault.name}"
# left as an example
#    elite_api_gateway_private_key = "elite-api-gateway-private-key"
  }
}

resource "azurerm_key_vault" "vault" {
  name                = "${var.env-name}"
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
