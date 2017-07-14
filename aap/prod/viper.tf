variable "viper-name" {
    type = "string"
    default = "viper-prod"
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

// use -target to create the app to allow terraform to compute this
resource "azurerm_sql_firewall_rule" "viper-access" {
    count = "${length(split(",", azurerm_template_deployment.viper.outputs["ips"]))}"
    name = "Viper Application IP ${count.index}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    server_name = "${module.sql.server_name}"
    start_ip_address = "${element(split(",", azurerm_template_deployment.viper.outputs["ips"]), count.index)}"
    end_ip_address = "${element(split(",", azurerm_template_deployment.viper.outputs["ips"]), count.index)}"
}

resource "azurerm_template_deployment" "viper-whitelist" {
    name = "viper-whitelist"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-whitelist.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.viper.parameters.name}"
        ip1 = "${var.ips["office"]}"
        ip2 = "${azurerm_template_deployment.api.outputs["ip"]}"
        ip3 = "${var.ips["health-kick"]}"
    }

    depends_on = ["azurerm_template_deployment.viper"]
}
