variable "ui-name" {
  type = "string"
  default = "licences-mock"
}

resource "azurerm_template_deployment" "ui" {
  name = "ui"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../../shared/appservice.template.json")}"
  parameters {
    name = "${var.ui-name}"
    service = "${var.tags["Service"]}"
    environment = "${var.tags["Environment"]}"
    workers = "1"
    sku_name = "S1"
    sku_tier = "Standard"
  }
}

resource "azurerm_template_deployment" "ui-config" {
  name = "ui-config"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../webapp-config.template.json")}"

  parameters {
    name = "${var.ui-name}"
    NODE_ENV = "production"
    SESSION_SECRET = "${random_id.session-secret.b64}"
    APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_template_deployment.insights.outputs["instrumentationKey"]}"
    DB_USER = "ui"
    DB_PASS = "${random_id.sql-ui-password.b64}"
    DB_SERVER = "${module.sql.db_server}"
    DB_NAME = "${module.sql.db_name}"
    LICENCES_API_URL = "https://licences-api-mock.hmpps.dsd.io/"
  }

  depends_on = ["azurerm_template_deployment.ui"]
}

resource "azurerm_template_deployment" "ui-ssl" {
  name = "ui-ssl"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../../shared/appservice-ssl.template.json")}"

  parameters {
    name = "${azurerm_template_deployment.ui.parameters.name}"
    hostname = "${azurerm_dns_cname_record.ui.name}.${azurerm_dns_cname_record.ui.zone_name}"
    keyVaultId = "${azurerm_key_vault.vault.id}"
    keyVaultCertName = "${replace("${azurerm_dns_cname_record.cname.name}.${azurerm_dns_cname_record.cname.zone_name}", ".", "DOT")}"
    service = "${var.tags["Service"]}"
    environment = "${var.tags["Environment"]}"
  }

  depends_on = ["azurerm_template_deployment.ui"]
}

resource "azurerm_template_deployment" "ui-github" {
  name = "ui-github"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode = "Incremental"
  template_body = "${file("../../shared/appservice-scm.template.json")}"

  parameters {
    name = "${var.ui-name}"
    repoURL = "https://github.com/noms-digital-studio/licences"
    branch = "deploy-to-mock"
  }

  depends_on = ["azurerm_template_deployment.ui"]
}

resource "github_repository_webhook" "ui-deploy" {
  repository = "licences"

  name = "ui"
  configuration {
    url = "${azurerm_template_deployment.ui-github.outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }
  active = true

  events = ["push"]
}

module "slackhook" {
  source = "../../shared/modules/slackhook"
  app_name = "${azurerm_template_deployment.ui.parameters.name}"
  channels = ["licences-dev"]
}

resource "azurerm_dns_cname_record" "ui" {
  name = "licences-mock"
  zone_name = "hmpps.dsd.io"
  resource_group_name = "webops"
  ttl = "300"
  record = "${var.ui-name}.azurewebsites.net"
  tags = "${var.tags}"
}