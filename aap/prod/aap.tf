terraform {
    required_version = ">= 0.9.2"
    backend "azure" {
        resource_group_name = "webops-prod"
        storage_account_name = "nomsstudiowebopsprod"
        container_name = "terraform"
        key = "aap-prod.terraform.tfstate"
        arm_subscription_id = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
        arm_tenant_id = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
    }
}

variable "env-name" {
    type = "string"
    default = "aap-prod"
}
variable "tags" {
    type = "map"
    default {
        Service = "AAP"
        Environment = "Prod"
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
    edition = "Standard"
    requested_service_objective_name = "S1"
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
