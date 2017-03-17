terraform {
    required_version = ">= 0.9.0"
    backend "azure" {
        resource_group_name = "webops"
        storage_account_name = "nomsstudiowebops"
        container_name = "terraform"
        key = "iis-stage.terraform.tfstate"
        arm_subscription_id = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
        arm_tenant_id = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
    }
}

variable "app-name" {
    type = "string"
    default = "iis-stage"
}
variable "tags" {
    type = "map"
    default {
        Service = "IIS"
        Environment = "Stage"
    }
}

resource "azurerm_resource_group" "group" {
    name = "${var.app-name}"
    location = "ukwest"
    tags = "${var.tags}"
}

resource "random_id" "sql-admin-password" {
    byte_length = 16
}
resource "random_id" "sql-user-password" {
    byte_length = 16
}

resource "azurerm_sql_server" "sql" {
    name = "${var.app-name}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    location = "${azurerm_resource_group.group.location}"
    version = "12.0"
    administrator_login = "iis"
    administrator_login_password = "${random_id.sql-admin-password.b64}"
    tags = "${var.tags}"
}

resource "azurerm_sql_firewall_rule" "office-access" {
    name = "NOMS Studio office"
    resource_group_name = "${azurerm_resource_group.group.name}"
    server_name = "${azurerm_sql_server.sql.name}"
    start_ip_address = "${var.ips["office"]}"
    end_ip_address = "${var.ips["office"]}"
}

resource "azurerm_sql_firewall_rule" "app-access" {
    count = "${length(split(",", azurerm_template_deployment.webapp.outputs.ips))}"
    name = "Application IP ${count.index}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    server_name = "${azurerm_sql_server.sql.name}"
    start_ip_address = "${element(split(",", azurerm_template_deployment.webapp.outputs.ips), count.index)}"
    end_ip_address = "${element(split(",", azurerm_template_deployment.webapp.outputs.ips), count.index)}"
}

resource "azurerm_sql_database" "db" {
    name = "${var.app-name}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    location = "${azurerm_resource_group.group.location}"
    server_name = "${azurerm_sql_server.sql.name}"
    edition = "Basic"
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

resource "azurerm_template_deployment" "webapp" {
    name = "${var.app-name}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../webapp.template.json")}"
    parameters {
        name = "${var.app-name}"
        hostname = "${azurerm_dns_cname_record.cname.name}.${azurerm_dns_cname_record.cname.zone_name}"
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
        DB_USER = "iis-user"
        DB_PASS = "${random_id.sql-user-password.b64}"
        DB_SERVER = "${azurerm_sql_server.sql.fully_qualified_domain_name}"
        DB_NAME = "${azurerm_sql_database.db.name}"
    }
}

resource "azurerm_dns_cname_record" "cname" {
    name = "hpa-stage"
    zone_name = "noms.dsd.io"
    resource_group_name = "webops"
    ttl = "300"
    record = "${var.app-name}.azurewebsites.net"
    tags {
        Service = "IIS"
        Environment = "Stage"
    }
}

# The "production" site currently uses this non-production DNS entry
# which can only be configured via the non-prod subscription
resource "azurerm_dns_cname_record" "prod-cname" {
    name = "hpa.service"
    zone_name = "hmpps.dsd.io"
    resource_group_name = "webops"
    ttl = "300"
    record = "iis-prod.azurewebsites.net"
    tags {
        Service = "IIS"
        Environment = "Prod"
    }
}

output "advice" {
    value = "Don't forget to set up the SQL instance user/schemas manually."
}
