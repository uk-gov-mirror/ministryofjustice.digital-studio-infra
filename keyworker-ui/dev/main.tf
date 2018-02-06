variable "env-name" {
    type = "string"
    default = "omic-dev"
}

variable "tags" {
    type = "map"
    default {
        Service = "omic"
        Environment = "Dev"
    }
}

resource "random_id" "session-secret" {
  byte_length = 40
}

resource "azurerm_app_service_plan" "omic-ui" {
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

resource "azurerm_app_service" "omic-ui" {
  name                = "${var.env-name}"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  app_service_plan_id = "${azurerm_app_service_plan.omic-ui.id}"

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
    api_gateway_private_key = "api-gateway-private-key"
    api_gateway_token = "api-gateway-token"
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
    object_id          = "${var.azure_notm_group_oid}"
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


resource "azurerm_template_deployment" "webapp" {
  name = "webapp"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../../shared/appservice.template.json")}"
  parameters {
    name = "${var.env-name}"
    service = "${var.tags["Service"]}"
    environment = "${var.tags["Environment"]}"
    workers = "1"
    sku_name = "S1"
    sku_tier = "Standard"
  }
}

resource "azurerm_template_deployment" "insights" {
  name = "${var.env-name}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../../shared/insights.template.json")}"
  parameters {
    name = "${var.env-name}"
    location = "northeurope" // Not in UK yet
    service = "${var.tags["Service"]}"
    environment = "${var.tags["Environment"]}"
    appServiceId = "${azurerm_template_deployment.webapp.outputs["resourceId"]}"
  }
}

resource "azurerm_template_deployment" "webapp-config" {
  name = "webapp-config"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../webapp-config.template.json")}"

  parameters {
    name = "${var.env-name}"
    APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_template_deployment.insights.outputs["instrumentationKey"]}"
    NODE_ENV = "production"
    API_ENDPOINT_URL = "https://noms-api-dev.dsd.io/elite2api/"
    USE_API_GATEWAY_AUTH = "yes"
    API_GATEWAY_TOKEN = "${data.external.vault.result.api_gateway_token}"
    API_GATEWAY_PRIVATE_KEY = "${data.external.vault.result.api_gateway_private_key}"
    SESSION_SECRET = "${random_id.session-secret.b64}"
  }

  depends_on = ["azurerm_template_deployment.webapp"]
}

resource "azurerm_template_deployment" "webapp-ssl" {
  name = "webapp-ssl"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../../shared/appservice-ssl.template.json")}"

  parameters {
    name = "${azurerm_template_deployment.webapp.parameters.name}"
    hostname = "${azurerm_dns_cname_record.cname.name}.${azurerm_dns_cname_record.cname.zone_name}"
    keyVaultId = "${azurerm_key_vault.vault.id}"
    keyVaultCertName = "${replace("${azurerm_dns_cname_record.cname.name}.${azurerm_dns_cname_record.cname.zone_name}", ".", "DOT")}"
    service = "${var.tags["Service"]}"
    environment = "${var.tags["Environment"]}"
  }

  depends_on = ["azurerm_template_deployment.webapp"]
}


module "slackhook" {
  source = "../../shared/modules/slackhook"
  app_name = "${azurerm_template_deployment.webapp.parameters.name}"
  channels = ["omic-dev"]
}

resource "azurerm_dns_cname_record" "cname" {
  name = "omic-dev"
  zone_name = "hmpps.dsd.io"
  resource_group_name = "webops"
  ttl = "300"
  record = "${var.env-name}.azurewebsites.net"
  tags = "${var.tags}"
}

