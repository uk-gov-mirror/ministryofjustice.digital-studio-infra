variable "nomis-batchload-name" {
  type    = "string"
  default = "nomis-batchload-mock"
}

resource "azurerm_app_service_plan" "nomis-batchload" {
  name                = "${var.nomis-batchload-name}"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"

  sku {
    tier     = "Standard"
    size     = "S1"
    capacity = 1
  }
}

resource "azurerm_app_service" "nomis-batchload" {
  name                = "${var.nomis-batchload-name}"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  app_service_plan_id = "${azurerm_app_service_plan.nomis-batchload.id}"

  app_settings {
    WEBSITE_NODE_DEFAULT_VERSION = "8.4.0"

    NODE_ENV          = "production"
    SESSION_SECRET    = "${random_id.session-secret.b64}"
    DB_USER           = "app"
    DB_PASS           = "${random_id.sql-nomis-batchload-password.b64}"
    DB_SERVER         = "${module.sql-nomis-batchload.db_server}"
    DB_NAME           = "${module.sql-nomis-batchload.db_name}"
    BATCH_USER_ROLES = "LICENCE_ADMIN"
    BATCH_SYSTEM_USER = "NOMIS_BATCH"
    BATCH_SYSTEM_PASSWORD = "${data.external.vault-nomis-batchload.result.elite_api_gateway_batch_system_key}"
    BATCH_SYSTEM_USER_ROLES = "SYSTEM_USER"
    NOMIS_API_URL     = "https://licences-nomis-mocks.herokuapp.com/elite2api"
    NOMIS_GW_TOKEN = "xxx.yyy.zzz"
    NOMIS_GW_KEY   = "${data.external.vault-nomis-batchload.result.elite_api_gateway_private_key}"
  }
}

data "external" "vault-nomis-batchload" {
  program = ["node", "../../tools/keyvault-data-cli-auth.js"]

  query {
    vault = "${azurerm_key_vault.vault.name}"
    elite_api_gateway_private_key = "elite-api-gateway-private-key"
    elite_api_gateway_batch_system_key = "elite-api-gateway-batch-system-key"
  }
}

resource "azurerm_template_deployment" "nomis-batchload-ssl" {
  name                = "nomis-batchload-ssl"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../../shared/appservice-ssl.template.json")}"

  parameters {
    name             = "${azurerm_app_service.nomis-batchload.name}"
    hostname         = "${azurerm_dns_cname_record.nomis-batchload.name}.${azurerm_dns_cname_record.nomis-batchload.zone_name}"
    keyVaultId       = "${azurerm_key_vault.vault.id}"
    keyVaultCertName = "${replace("${azurerm_dns_cname_record.nomis-batchload.name}.${azurerm_dns_cname_record.nomis-batchload.zone_name}", ".", "DOT")}"
    service          = "${var.tags["Service"]}"
    environment      = "${var.tags["Environment"]}"
  }
}

resource "azurerm_template_deployment" "nomis-batchload-github" {
  name                = "nomis-batchload-github"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../../shared/appservice-scm.template.json")}"

  parameters {
    name    = "${azurerm_app_service.nomis-batchload.name}"
    repoURL = "https://github.com/ministryofjustice/nomis-batchload"
    branch  = "deploy-to-mock"
  }
}

resource "github_repository_webhook" "nomis-batchload-deploy" {
  provider = "github.moj"
  repository = "nomis-batchload"

  name = "web"

  configuration {
    url          = "${azurerm_template_deployment.nomis-batchload-github.outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }

  active = true

  events = ["push"]
}

resource "azurerm_template_deployment" "nomis-batchload-weblogs" {
  name                = "nomis-batchload-weblogs"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../../shared/appservice-weblogs.template.json")}"

  parameters {
    name       = "${azurerm_app_service.nomis-batchload.name}"
    storageSAS = "${data.external.sas-url.result["url"]}"
  }
}

module "slackhook-nomis-batchload" {
  source   = "../../shared/modules/slackhook"
  app_name = "${azurerm_app_service.nomis-batchload.name}"
  channels = ["licences-dev"]
}

resource "azurerm_dns_cname_record" "nomis-batchload" {
  name                = "nomis-batchload-mock"
  zone_name           = "hmpps.dsd.io"
  resource_group_name = "webops"
  ttl                 = "300"
  record              = "${var.nomis-batchload-name}.azurewebsites.net"
  tags                = "${var.tags}"
}
