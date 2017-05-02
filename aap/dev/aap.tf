terraform {
    required_version = ">= 0.9.2"
    backend "azure" {
        resource_group_name = "webops"
        storage_account_name = "nomsstudiowebops"
        container_name = "terraform"
        key = "aap-dev.terraform.tfstate"
        arm_subscription_id = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
        arm_tenant_id = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
    }
}

variable "env-name" {
    type = "string"
    default = "aap-dev"
}
variable "viper-name" {
    type = "string"
    default = "viper-dev"
}
variable "tags" {
    type = "map"
    default {
        Service = "AAP"
        Environment = "Dev"
    }
}

resource "azurerm_resource_group" "group" {
    name = "${var.env-name}"
    location = "ukwest"
    tags = "${var.tags}"
}

resource "random_id" "sql-admin-password" {
    byte_length = 32
}

resource "azurerm_storage_account" "storage" {
    name = "${replace(var.env-name, "-", "")}storage"
    resource_group_name = "${azurerm_resource_group.group.name}"
    location = "${azurerm_resource_group.group.location}"
    account_type = "Standard_RAGRS"
    enable_blob_encryption = true

    tags = "${var.tags}"
}

resource "azurerm_sql_server" "sql" {
    name = "${var.env-name}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    location = "${azurerm_resource_group.group.location}"
    version = "12.0"
    administrator_login = "aap"
    administrator_login_password = "${random_id.sql-admin-password.b64}"
    tags = "${var.tags}"
}

resource "azurerm_sql_firewall_rule" "azure-services" {
    name = "Allow azure access"
    resource_group_name = "${azurerm_resource_group.group.name}"
    server_name = "${azurerm_sql_server.sql.name}"
    start_ip_address = "0.0.0.0"
    end_ip_address = "0.0.0.0"
}
resource "azurerm_sql_firewall_rule" "world-open" {
    name = "Open to the world"
    resource_group_name = "${azurerm_resource_group.group.name}"
    server_name = "${azurerm_sql_server.sql.name}"
    start_ip_address = "0.0.0.0"
    end_ip_address = "255.255.255.255"
}

resource "azurerm_sql_database" "db" {
    name = "${var.env-name}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    location = "${azurerm_resource_group.group.location}"
    server_name = "${azurerm_sql_server.sql.name}"
    edition = "Basic"
    collation = "SQL_Latin1_General_CP1_CI_AS"
    tags = "${var.tags}"
}

resource "azurerm_template_deployment" "sql-tde" {
    name = "sql-tde"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/azure-sql-tde.template.json")}"
    parameters {
        serverName = "${azurerm_sql_server.sql.name}"
        databaseName = "${azurerm_sql_database.db.name}"
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
    }
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

resource "azurerm_template_deployment" "viper-hostname" {
    name = "viper-hostname"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-hostname.template.json")}"

    parameters {
        name = "${var.viper-name}"
        hostname = "${azurerm_dns_cname_record.viper.name}.${azurerm_dns_cname_record.viper.zone_name}"
    }

    depends_on = ["azurerm_template_deployment.viper"]
}

resource "azurerm_dns_cname_record" "viper" {
    name = "${var.viper-name}"
    zone_name = "hmpps.dsd.io"
    resource_group_name = "webops"
    ttl = "300"
    record = "${var.viper-name}.azurewebsites.net"
    tags = "${var.tags}"
}

resource "azurerm_template_deployment" "viper-github" {
    name = "viper-github"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-scm.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.viper.parameters.name}"
        repoURL = "https://github.com/noms-digital-studio/viper-service.git"
        branch = "master"
    }

    depends_on = ["azurerm_template_deployment.viper"]
}

resource "github_repository_webhook" "viper-deploy" {
  repository = "viper-service"

  name = "web"
  configuration {
    url = "${azurerm_template_deployment.viper-github.outputs.deployTrigger}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }
  active = true

  events = ["push"]
}
