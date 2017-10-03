variable "licences-api-name" {
  type = "string"
  default = "licences-api-mock"
}

resource "azurerm_template_deployment" "licences-api" {
  name = "licences-api"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../../shared/appservice.template.json")}"
  parameters {
    name = "${var.licences-api-name}"
    service = "${var.tags["Service"]}"
    environment = "${var.tags["Environment"]}"
    workers = "1"
    sku_name = "S1"
    sku_tier = "Standard"
  }
}

resource "azurerm_template_deployment" "licences-api-config" {
  name = "licences-api-config"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../webapp-config.template.json")}"

  parameters {
    name = "${var.licences-api-name}"
    NODE_ENV = "production"
    SESSION_SECRET = "${random_id.session-secret.b64}"
    APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_template_deployment.insights.outputs["instrumentationKey"]}"
    DB_USER = "api"
    DB_PASS = "${random_id.sql-api-password.b64}"
    DB_SERVER = "${module.sql.db_server}"
    DB_NAME = "${module.sql.db_name}"
    NOMIS_API_URL = "https://licences-nomis-mocks.herokuapp.com/"
  }

  depends_on = ["azurerm_template_deployment.webapp"]
}

resource "azurerm_template_deployment" "licences-api-ssl" {
  name = "licences-api-ssl"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../../shared/appservice-ssl.template.json")}"

  parameters {
    name = "${azurerm_template_deployment.licences-api.parameters.name}"
    hostname = "${azurerm_dns_cname_record.licences-api.name}.${azurerm_dns_cname_record.licences-api.zone_name}"
    keyVaultId = "${azurerm_key_vault.vault.id}"
    keyVaultCertName = "${replace("${azurerm_dns_cname_record.cname.name}.${azurerm_dns_cname_record.cname.zone_name}", ".", "DOT")}"
    service = "${var.tags["Service"]}"
    environment = "${var.tags["Environment"]}"
  }

  depends_on = ["azurerm_template_deployment.webapp"]
}

resource "azurerm_template_deployment" "licences-api-github" {
  name = "licences-api-github"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../../shared/appservice-scm.template.json")}"

  parameters {
    name = "${var.licences-api-name}"
    repoURL = "https://github.com/noms-digital-studio/licences-api"
    branch = "deploy-to-mock"
  }

  depends_on = ["azurerm_template_deployment.licences-api"]
}

resource "github_repository_webhook" "webapp-deploy" {
  repository = "licences"

  name = "web"
  configuration {
    url = "${azurerm_template_deployment.licences-api-github.outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }
  active = true

  events = ["push"]
}

module "slackhook" {
  source = "../../shared/modules/slackhook"
  app_name = "${azurerm_template_deployment.licences-api.parameters.name}"
  channels = ["licences-dev"]
}

resource "azurerm_dns_cname_record" "licences-api" {
  name = "licences-api-mock"
  zone_name = "hmpps.dsd.io"
  resource_group_name = "webops"
  ttl = "300"
  record = "${var.licences-api-name}.azurewebsites.net"
  tags = "${var.tags}"
}