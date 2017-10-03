variable "licences-name" {
  type = "string"
  default = "licences-mock"
}

resource "azurerm_template_deployment" "licences-ui" {
  name = "licences-ui"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../../shared/appservice.template.json")}"
  parameters {
    name = "${var.licences-name}"
    service = "${var.tags["Service"]}"
    environment = "${var.tags["Environment"]}"
    workers = "1"
    sku_name = "S1"
    sku_tier = "Standard"
  }
}

resource "azurerm_template_deployment" "licences-ui-config" {
  name = "licences-ui-config"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../webapp-config.template.json")}"

  parameters {
    name = "${var.licences-name}"
    NODE_ENV = "production"
    SESSION_SECRET = "${random_id.session-secret.b64}"
    APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_template_deployment.insights.outputs["instrumentationKey"]}"
    DB_USER = "ui"
    DB_PASS = "${random_id.sql-ui-password.b64}"
    DB_SERVER = "${module.sql.db_server}"
    DB_NAME = "${module.sql.db_name}"
    LICENCES_API_URL = "https://licences-api-mocks.herokuapp.com/"
  }

  depends_on = ["azurerm_template_deployment.webapp"]
}

resource "azurerm_template_deployment" "licences-ui-ssl" {
  name = "licences-ui-ssl"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../../shared/appservice-ssl.template.json")}"

  parameters {
    name = "${azurerm_template_deployment.licences-ui.parameters.name}"
    hostname = "${azurerm_dns_cname_record.licences-ui.name}.${azurerm_dns_cname_record.licences-ui.zone_name}"
    keyVaultId = "${azurerm_key_vault.vault.id}"
    keyVaultCertName = "${replace("${azurerm_dns_cname_record.cname.name}.${azurerm_dns_cname_record.cname.zone_name}", ".", "DOT")}"
    service = "${var.tags["Service"]}"
    environment = "${var.tags["Environment"]}"
  }

  depends_on = ["azurerm_template_deployment.webapp"]
}

resource "azurerm_template_deployment" "licences-ui-github" {
  name = "licences-ui-github"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../../shared/appservice-scm.template.json")}"

  parameters {
    name = "${var.licences-name}"
    repoURL = "https://github.com/noms-digital-studio/licences"
    branch = "deploy-to-mock"
  }

  depends_on = ["azurerm_template_deployment.licences-ui"]
}

resource "github_repository_webhook" "licences-ui-deploy" {
  repository = "licences"

  name = "licences-ui"
  configuration {
    url = "${azurerm_template_deployment.licences-ui-github.outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }
  active = true

  events = ["push"]
}

module "slackhook" {
  source = "../../shared/modules/slackhook"
  app_name = "${azurerm_template_deployment.licences-ui.parameters.name}"
  channels = ["licences-dev"]
}

resource "azurerm_dns_cname_record" "licences-ui" {
  name = "licences-mock"
  zone_name = "hmpps.dsd.io"
  resource_group_name = "webops"
  ttl = "300"
  record = "${var.licences-name}.azurewebsites.net"
  tags = "${var.tags}"
}