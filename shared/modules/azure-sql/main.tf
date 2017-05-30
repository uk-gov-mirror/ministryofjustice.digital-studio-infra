variable "name" {
    type = "string"
}
variable "resource_group" {
    type = "string"
}
variable "location" {
    type = "string"
}
variable "administrator_login" {
    type = "string"
}
variable "firewall_rules" {
    type = "list"
    default = [
        # for example
        # {
        #     label = "value"
        #     start = "0.0.0.0"
        #     end = "0.0.0.0"
        # },
    ]
}
variable "edition" {
    type = "string"
    default = "Basic"
}
variable "scale" {
    type = "string"
    default = ""
    # eg "S3"
}
variable "collation" {
    type = "string"
    default = "SQL_Latin1_General_CP1_CI_AS"
}
variable "tags" {
    type = "map"
    # default {
    #    Service = "xxx"
    #    Environment = "xxx"
    # }
}

resource "random_id" "sql-admin-password" {
    byte_length = 32
}

resource "azurerm_sql_server" "sql" {
    name = "${var.name}"
    resource_group_name = "${var.resource_group}"
    location = "${var.location}"
    version = "12.0"
    administrator_login = "${var.administrator_login}"
    administrator_login_password = "${random_id.sql-admin-password.b64}"
    tags = "${var.tags}"
}

resource "azurerm_sql_firewall_rule" "firewall" {
    count = "${length(var.firewall_rules)}"
    name = "${lookup(var.firewall_rules[count.index], "label")}"
    resource_group_name = "${var.resource_group}"
    server_name = "${azurerm_sql_server.sql.name}"
    start_ip_address = "${lookup(var.firewall_rules[count.index], "start")}"
    end_ip_address = "${lookup(var.firewall_rules[count.index], "end")}"
}

resource "azurerm_sql_database" "db" {
    name = "${var.name}"
    resource_group_name = "${var.resource_group}"
    location = "${var.location}"
    server_name = "${azurerm_sql_server.sql.name}"
    edition = "${var.edition}"
    collation = "SQL_Latin1_General_CP1_CI_AS"
    tags = "${var.tags}"
}

resource "azurerm_template_deployment" "sql-tde" {
    name = "sql-tde"
    resource_group_name = "${var.resource_group}"
    deployment_mode = "Incremental"
    template_body = "${file("${path.module}/../../azure-sql-tde.template.json")}"
    parameters {
        serverName = "${azurerm_sql_server.sql.name}"
        databaseName = "${azurerm_sql_database.db.name}"
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
    }
}
