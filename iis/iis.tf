resource "azurerm_resource_group" "iis-dev" {
    name = "iis-dev"
    location = "ukwest"
    tags {
      Service = "IIS"
      Environment = "dev"
    }
}

resource "random_id" "iis-dev-sql-password" {
    byte_length = 16
}

resource "azurerm_sql_server" "iis-dev" {
    name = "iis-dev"
    resource_group_name = "${azurerm_resource_group.iis-dev.name}"
    location = "${azurerm_resource_group.iis-dev.location}"
    version = "12.0"
    administrator_login = "iis"
    administrator_login_password = "${random_id.iis-dev-sql-password.b64}"
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

resource "azurerm_template_deployment" "iis-dev" {
  name = "iis-dev"
  resource_group_name = "${azurerm_resource_group.iis-dev.name}"
  deployment_mode = "Incremental"
  template_body = "${file("./webapp.template.json")}"
  parameters {
    name = "iis-dev"
    service = "IIS"
    environment = "dev"
  }
}
