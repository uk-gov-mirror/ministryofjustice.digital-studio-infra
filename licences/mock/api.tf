variable "api-name" {
  type = "string"
  default = "licences-api-mock"
}

resource "azurerm_template_deployment" "api" {
  name = "api"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../../shared/appservice.template.json")}"
  parameters {
    name = "${var.api-name}"
    service = "${var.tags["Service"]}"
    environment = "${var.tags["Environment"]}"
    workers = "1"
    sku_name = "S1"
    sku_tier = "Standard"
  }
}

resource "azurerm_template_deployment" "api-config" {
  name = "api-config"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../api-config.template.json")}"

  parameters {
    name = "${var.api-name}"
    NODE_ENV = "production"
    SESSION_SECRET = "${random_id.session-secret.b64}"
    APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_template_deployment.insights.outputs["instrumentationKey"]}"
    DB_USER = "api"
    DB_PASS = "${random_id.sql-api-password.b64}"
    DB_SERVER = "${module.sql.db_server}"
    DB_NAME = "${module.sql.db_name}"
    NOMIS_API_URL = "https://licences-nomis-mocks.herokuapp.com/"
  }

  depends_on = ["azurerm_template_deployment.api"]
}

resource "azurerm_template_deployment" "api-ssl" {
  name = "api-ssl"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../../shared/appservice-ssl.template.json")}"

  parameters {
    name = "${azurerm_template_deployment.api.parameters.name}"
    hostname = "${azurerm_dns_cname_record.api.name}.${azurerm_dns_cname_record.api.zone_name}"
    keyVaultId = "${azurerm_key_vault.vault.id}"
    keyVaultCertName = "${replace("${azurerm_dns_cname_record.api.name}.${azurerm_dns_cname_record.api.zone_name}", ".", "DOT")}"
    service = "${var.tags["Service"]}"
    environment = "${var.tags["Environment"]}"
  }

  depends_on = ["azurerm_template_deployment.api"]
}

resource "azurerm_template_deployment" "api-github" {
  name = "api-github"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../../shared/appservice-scm.template.json")}"

  parameters {
    name = "${var.api-name}"
    repoURL = "https://github.com/noms-digital-studio/licences-api"
    branch = "deploy-to-mock"
  }

  depends_on = ["azurerm_template_deployment.api"]
}

resource "github_repository_webhook" "api-deploy" {
  repository = "licences-api"

  name = "web"
  configuration {
    url = "${azurerm_template_deployment.api-github.outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }
  active = true

  events = ["push"]
}

resource "azurerm_template_deployment" "api-weblogs" {
    name = "api-weblogs"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-weblogs.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.api.parameters.name}"
        storageSAS = "${data.external.sas-url.result["url"]}"
    }
}

module "slackhook-api" {
  source = "../../shared/modules/slackhook"
  app_name = "${azurerm_template_deployment.api.parameters.name}"
  channels = ["licences-dev"]
}

resource "azurerm_dns_cname_record" "api" {
  name = "licences-api-mock"
  zone_name = "hmpps.dsd.io"
  resource_group_name = "webops"
  ttl = "300"
  record = "${azurerm_template_deployment.api.parameters.name}.azurewebsites.net"
  tags = "${var.tags}"
}
