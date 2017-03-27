terraform {
    required_version = ">= 0.9.0"
    backend "azure" {
        resource_group_name = "webops-prod"
        storage_account_name = "nomsstudiowebopsprod"
        container_name = "terraform"
        key = "iis-prod.terraform.tfstate"
        arm_subscription_id = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
        arm_tenant_id = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
    }
}

variable "app-name" {
    type = "string"
    default = "iis-prod"
}
variable "tags" {
    type = "map"
    default {
        Service = "IIS"
        Environment = "Prod"
    }
}

resource "azurerm_resource_group" "group" {
    name = "${var.app-name}"
    location = "ukwest"
    tags = "${var.tags}"
}

resource "random_id" "session-secret" {
    byte_length = 20
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
    edition = "Standard"
    requested_service_objective_name = "S3"
    collation = "Latin1_General_CS_AS"
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
        ip1 = "${var.ips["office"]}"
        subnet1 = "255.255.255.255"
        ip2 = "${var.ips["quantum"]}"
        subnet2 = "255.255.255.255"
        DB_USER = "iisuser"
        DB_PASS = "${random_id.sql-user-password.b64}"
        DB_SERVER = "${azurerm_sql_server.sql.fully_qualified_domain_name}"
        DB_NAME = "${azurerm_sql_database.db.name}"
        SESSION_SECRET = "${random_id.session-secret.b64}"
        CLIENT_ID = "TODO"
        CLIENT_SECRET = "TODO"
        TOKEN_HOST = "https://signon.service.justice.gov.uk"
    }
}

resource "azurerm_dns_cname_record" "cname" {
    name = "hpa"
    zone_name = "service.hmpps.dsd.io"
    resource_group_name = "webops-prod"
    ttl = "300"
    record = "${var.app-name}.azurewebsites.net"
    tags = "${var.tags}"
}

output "advice" {
    value = "Don't forget to set up the SQL instance user/schemas manually."
}
