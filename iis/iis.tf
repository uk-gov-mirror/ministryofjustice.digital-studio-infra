resource "azurerm_resource_group" "iis-dev" {
    name = "iis-dev"
    location = "ukwest"
    tags {
      Service = "IIS"
      Environment = "dev"
    }
}

resource "random_id" "iis-dev-sql-admin-password" {
    byte_length = 16
}
resource "random_id" "iis-dev-sql-user-password" {
    byte_length = 16
}

resource "azurerm_sql_server" "iis-dev" {
    name = "iis-dev"
    resource_group_name = "${azurerm_resource_group.iis-dev.name}"
    location = "${azurerm_resource_group.iis-dev.location}"
    version = "12.0"
    administrator_login = "iis"
    administrator_login_password = "${random_id.iis-dev-sql-admin-password.b64}"
    tags {
        Service = "IIS"
        Environment = "dev"
    }
}

resource "azurerm_sql_firewall_rule" "iis-dev" {
    name = "Open to the world (for now)"
    resource_group_name = "${azurerm_resource_group.iis-dev.name}"
    server_name = "${azurerm_sql_server.iis-dev.name}"
    start_ip_address = "0.0.0.0"
    end_ip_address = "255.255.255.255"
}

resource "azurerm_sql_database" "iis-dev" {
    name = "iis-dev"
    resource_group_name = "${azurerm_resource_group.iis-dev.name}"
    location = "${azurerm_resource_group.iis-dev.location}"
    server_name = "${azurerm_sql_server.iis-dev.name}"
    edition = "Basic"
    tags {
        Service = "IIS"
        Environment = "dev"
    }
}

resource "azurerm_template_deployment" "iis-dev-webapp" {
    name = "iis-dev"
    resource_group_name = "${azurerm_resource_group.iis-dev.name}"
    deployment_mode = "Incremental"
    template_body = "${file("./webapp.template.json")}"
    parameters {
        name = "iis-dev"
        hostname = "iis-dev.noms.dsd.io"
        service = "IIS"
        environment = "dev"
        DB_USER = "iis-user"
        DB_PASS = "${random_id.iis-dev-sql-user-password.b64}"
        DB_SERVER = "${azurerm_sql_server.iis-dev.fully_qualified_domain_name}"
        DB_NAME = "${azurerm_sql_database.iis-dev.name}"
    }
}

resource "azurerm_dns_cname_record" "iis-dev" {
    name = "iis-dev"
    zone_name = "noms.dsd.io"
    resource_group_name = "webops"
    ttl = "300"
    record = "iis-dev.azurewebsites.net"
    tags {
        Service = "IIS"
        Environment = "dev"
    }
}
