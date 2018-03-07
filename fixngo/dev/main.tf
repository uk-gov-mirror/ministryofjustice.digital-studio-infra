
variable "env-name" {
  type    = "string"
  default = "fixngo-dev"
}

variable "app-name" {
  type    = "string"
  default = "fixngo-map"
}

variable "tags" {
  type = "map"

  default {
    Service     = "WebOps"
    Environment = "Dev"
  }
}

resource "azurerm_resource_group" "group" {
  name     = "${var.env-name}"
  location = "ukwest"
  tags     = "${var.tags}"
}

resource "azurerm_app_service_plan" "webapp" {
  name                = "${var.app-name}"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  kind                = "Linux"

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_application_insights" "insights" {
  name                = "${var.env-name}"
  location            = "northeurope"
  resource_group_name = "${azurerm_resource_group.group.name}"
  application_type    = "Web"
  tags                = "${var.tags}"
}

resource "azurerm_app_service" "webapp" {
  name                = "${var.app-name}"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  app_service_plan_id = "${azurerm_app_service_plan.webapp.id}"

  app_settings {
    NODE_ENV                       = "production"
    WEBSITE_NODE_DEFAULT_VERSION   = "8.4.0"
    APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_application_insights.insights.instrumentation_key}"
    ARM_SUBSCRIPTIONS              = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
  }
}

resource "azurerm_template_deployment" "webapp-auth" {
  name                = "webapp-auth"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../fixngo-authsettings.template.json")}"

  parameters {
    name = "${azurerm_app_service.webapp.name}"
  }
}

resource "azurerm_template_deployment" "webapp-ssl" {
  name                = "webapp-ssl"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../../shared/appservice-sslonly.template.json")}"

  parameters {
    name = "${azurerm_app_service.webapp.name}"
  }
}

resource "azurerm_template_deployment" "webapp-github" {
  name                = "webapp-github"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../../shared/appservice-scm.template.json")}"

  parameters {
    name    = "${azurerm_app_service.webapp.name}"
    repoURL = "https://github.com/ministryofjustice/hmpps-estate-map"
    branch  = "master"
  }
}

resource "github_repository_webhook" "webapp-deploy" {
  repository = "hmpps-estate-map"

  name = "web"

  configuration {
    url          = "${azurerm_template_deployment.webapp-github.outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }

  active = true

  events = ["push"]
}
