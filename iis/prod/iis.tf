resource "azurerm_resource_group" "iis-prod" {
    name = "iis-prod"
    location = "ukwest"
    tags {
      Service = "IIS"
      Environment = "Prod"
    }
}

resource "random_id" "iis-prod-sql-admin-password" {
    byte_length = 16
}
resource "random_id" "iis-prod-sql-user-password" {
    byte_length = 16
}

resource "azurerm_sql_server" "iis-prod" {
    name = "iis-prod"
    resource_group_name = "${azurerm_resource_group.iis-prod.name}"
    location = "${azurerm_resource_group.iis-prod.location}"
    version = "12.0"
    administrator_login = "iis"
    administrator_login_password = "${random_id.iis-prod-sql-admin-password.b64}"
    tags {
        Service = "IIS"
        Environment = "Prod"
    }
}

# resource "azurerm_sql_firewall_rule" "iis-prod" {
#     name = "Closed to the world"
#     resource_group_name = "${azurerm_resource_group.iis-prod.name}"
#     server_name = "${azurerm_sql_server.iis-prod.name}"
#     start_ip_address = "0.0.0.0"
#     end_ip_address = "0.0.0.0"
# }

resource "azurerm_sql_database" "iis-prod" {
    name = "iis-prod"
    resource_group_name = "${azurerm_resource_group.iis-prod.name}"
    location = "${azurerm_resource_group.iis-prod.location}"
    server_name = "${azurerm_sql_server.iis-prod.name}"
    edition = "Standard"
    tags {
        Service = "IIS"
        Environment = "Prod"
    }
}

resource "azurerm_template_deployment" "iis-prod-sql-tde" {
    name = "iis-prod-sql-tde"
    resource_group_name = "${azurerm_resource_group.iis-prod.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/azure-sql-tde.template.json")}"
    parameters {
        serverName = "${azurerm_sql_server.iis-prod.name}"
        databaseName = "${azurerm_sql_database.iis-prod.name}"
        service = "IIS"
        environment = "Prod"
    }
}

resource "azurerm_template_deployment" "iis-prod-webapp" {
    name = "iis-prod"
    resource_group_name = "${azurerm_resource_group.iis-prod.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../webapp.template.json")}"
    parameters {
        name = "iis-prod"
        hostname = "hpa.service.hmpps.dsd.io"
        service = "IIS"
        environment = "Prod"
        DB_USER = "iis-user"
        DB_PASS = "${random_id.iis-prod-sql-user-password.b64}"
        DB_SERVER = "${azurerm_sql_server.iis-prod.fully_qualified_domain_name}"
        DB_NAME = "${azurerm_sql_database.iis-prod.name}"
    }
}

output "advice" {
    value = "Don't forget to set up the SQL instance user/schemas manually."
}
