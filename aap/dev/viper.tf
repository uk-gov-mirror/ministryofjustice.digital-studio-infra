variable "viper-name" {
    type = "string"
    default = "viper-dev"
}

resource "random_id" "app-basic-password" {
    byte_length = 32
}

resource "azurerm_template_deployment" "viper" {
    name = "viper"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice.template.json")}"
    parameters {
        name = "${var.viper-name}"
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
    }
}

resource "azurerm_template_deployment" "insights" {
    name = "${var.viper-name}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/insights.template.json")}"
    parameters {
        name = "${var.viper-name}"
        location = "northeurope" // Not in UK yet
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
        appServiceId = "${azurerm_template_deployment.viper.outputs["resourceId"]}"
    }
}

resource "azurerm_template_deployment" "viper-config" {
    name = "viper-config"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../viper-config.template.json")}"

    parameters {
        name = "${var.viper-name}"
        NODE_ENV = "production"
        BASIC_AUTH_USER = "viper"
        BASIC_AUTH_PASS = "${random_id.app-basic-password.b64}"
        DB_URI = "mssql://app:${random_id.sql-app-password.b64}@${module.sql.db_server}:1433/${module.sql.db_name}?encrypt=true"
        APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_template_deployment.insights.outputs["instrumentationKey"]}"
    }

    depends_on = ["azurerm_template_deployment.viper"]
}

resource "azurerm_template_deployment" "viper-ssl" {
    name = "viper-ssl"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-sslonly.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.viper.parameters.name}"
    }

    depends_on = ["azurerm_template_deployment.viper"]
}

resource "azurerm_template_deployment" "viper-github" {
    name = "viper-github"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-scm.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.viper.parameters.name}"
        repoURL = "https://github.com/noms-digital-studio/viper-service.git"
        branch = "deploy-to-dev"
    }

    depends_on = ["azurerm_template_deployment.viper"]
}

resource "github_repository_webhook" "viper-deploy" {
  repository = "viper-service"

  name = "web"
  configuration {
    url = "${azurerm_template_deployment.viper-github.outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }
  active = true

  events = ["push"]
}

module "slackhook" {
    source = "../../shared/modules/slackhook"
    app_name = "${azurerm_template_deployment.viper.parameters.name}"
    channels = ["api-accelerator"]
}
