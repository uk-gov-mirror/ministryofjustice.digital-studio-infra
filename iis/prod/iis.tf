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

resource "azurerm_storage_account" "storage" {
    name = "${replace(var.app-name, "-", "")}storage"
    resource_group_name = "${azurerm_resource_group.group.name}"
    location = "${azurerm_resource_group.group.location}"
    account_type = "Standard_RAGRS"
    enable_blob_encryption = true

    tags = "${var.tags}"
}

variable "log-containers" {
    type = "list"
    default = ["app-logs", "web-logs", "db-logs"]
}
resource "azurerm_storage_container" "logs" {
    count = "${length(var.log-containers)}"
    name = "${var.log-containers[count.index]}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    storage_account_name = "${azurerm_storage_account.storage.name}"
    container_access_type = "private"
}

resource "azurerm_key_vault" "vault" {
    name = "${var.app-name}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    location = "${azurerm_resource_group.group.location}"
    sku {
        name = "standard"
    }
    tenant_id = "${var.azure_tenant_id}"

    access_policy {
        tenant_id = "${var.azure_tenant_id}"
        object_id = "${var.azure_webops_group_oid}"
        key_permissions = ["all"]
        secret_permissions = ["all"]
    }
    access_policy {
        tenant_id = "${var.azure_tenant_id}"
        object_id = "${var.azure_app_service_oid}"
        key_permissions = []
        secret_permissions = ["get"]
    }
    access_policy {
        object_id = "${var.azure_glenm_tfprod_oid}"
        tenant_id = "${var.azure_tenant_id}"
        key_permissions = ["get"]
        secret_permissions = ["get"]
    }

    enabled_for_deployment = false
    enabled_for_disk_encryption = false
    enabled_for_template_deployment = true

    tags = "${var.tags}"
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

resource "azurerm_template_deployment" "sql-audit" {
    name = "sql-audit"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/azure-sql-audit.template.json")}"
    parameters {
        serverName = "${azurerm_sql_server.sql.name}"
        storageAccountName = "${azurerm_storage_account.storage.name}"
    }
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
    name = "webapp"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice.template.json")}"
    parameters {
        name = "${var.app-name}"
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
    }
}

data "external" "sas-url" {
    program = ["node", "../../tools/container-sas-url.js"]
    query {
        subscription_id = "${var.azure_subscription_id}"
        tenant_id = "${var.azure_tenant_id}"
        resource_group = "${azurerm_resource_group.group.name}"
        storage_account = "${azurerm_storage_account.storage.name}"
        container = "web-logs"
        permissions = "rwdl"
        start_date = "2017-05-15T00:00:00Z"
        end_date = "2217-05-15T00:00:00Z"
    }
}

resource "azurerm_template_deployment" "webapp-weblogs" {
    name = "webapp-weblogs"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-weblogs.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.webapp.parameters.name}"
        storageSAS = "${data.external.sas-url.result.url}"
    }

    depends_on = ["azurerm_template_deployment.webapp"]
}

resource "azurerm_template_deployment" "insights" {
    name = "${var.app-name}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/insights.template.json")}"
    parameters {
        name = "${azurerm_template_deployment.webapp.parameters.name}"
        location = "northeurope" // Not in UK yet
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
        appServiceId = "${azurerm_template_deployment.webapp.outputs["resourceId"]}"
    }
}

resource "azurerm_template_deployment" "webapp-whitelist" {
    name = "webapp-whitelist"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-whitelist.template.json")}"

    parameters {
        name = "${var.app-name}"
        ip1 = "${var.ips["office"]}"
        subnet1 = "255.255.255.255"
        ip2 = "${var.ips["quantum"]}"
        subnet2 = "255.255.255.255"
    }

    depends_on = ["azurerm_template_deployment.webapp"]
}

data "external" "vault" {
    program = ["node", "../../tools/keyvault-data.js"]
    query {
        vault = "${azurerm_key_vault.vault.name}"

        client_id = "signon-client-id"
        client_secret = "signon-client-secret"

        dashboard_token = "dashboard-token"
        appinsights_api_key = "appinsights-api-key"
    }
}

resource "azurerm_template_deployment" "webapp-config" {
    name = "webapp-config"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../webapp-config.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.webapp.parameters.name}"
        DB_USER = "iisuser"
        DB_PASS = "${random_id.sql-user-password.b64}"
        DB_SERVER = "${azurerm_sql_server.sql.fully_qualified_domain_name}"
        DB_NAME = "${azurerm_sql_database.db.name}"
        SESSION_SECRET = "${random_id.session-secret.b64}"
        CLIENT_ID = "${data.external.vault.result.client_id}"
        CLIENT_SECRET = "${data.external.vault.result.client_secret}"
        TOKEN_HOST = "https://signon.service.justice.gov.uk"
        HEALTHCHECK_INTERVAL = "5"
        APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_template_deployment.insights.outputs["instrumentationKey"]}"
    }

    depends_on = ["azurerm_template_deployment.webapp"]
}

resource "azurerm_template_deployment" "webapp-ssl" {
    name = "webapp-ssl"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-ssl.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.webapp.parameters.name}"
        hostname = "${azurerm_dns_cname_record.cname.name}.${azurerm_dns_cname_record.cname.zone_name}"
        keyVaultId = "${azurerm_key_vault.vault.id}"
        keyVaultCertName = "hpaDOTserviceDOThmppsDOTdsdDOTio"
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
    }

    depends_on = ["azurerm_template_deployment.webapp"]
}

resource "azurerm_dns_cname_record" "cname" {
    name = "hpa"
    zone_name = "service.hmpps.dsd.io"
    resource_group_name = "webops-prod"
    ttl = "300"
    record = "${var.app-name}.azurewebsites.net"
    tags = "${var.tags}"
}


resource "azurerm_template_deployment" "stats-exposer" {
    name = "stats-exposer-app"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice.template.json")}"
    parameters {
        name = "${var.app-name}-stats-exposer"
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
    }
}

resource "azurerm_template_deployment" "stats-expos-erconfig" {
    name = "stats-exposer-config"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../stats-webapp-config.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.stats-exposer.parameters.name}"
        DASHBOARD_TARGET = "https://iis-monitoring.herokuapp.com"
        DASHBOARD_TOKEN = "${data.external.vault.result.dashboard_token}"
        APPINSIGHTS_APP_ID = "5595f5b0-cfb0-4af0-ac47-f46f8abc2c1e"
        APPINSIGHTS_API_KEY = "${data.external.vault.result.appinsights_api_key}"
        APPINSIGHTS_UPDATE_INTERVAL = 15
        APPINSIGHTS_QUERY_week = "traces | where timestamp > ago(7d) | where message == 'AUDIT' | summarize count() by tostring(customDimensions.key)"
        APPINSIGHTS_QUERY_today = "traces | where timestamp > startofday(now()) | where message == 'AUDIT' | summarize count() by tostring(customDimensions.key)"
    }

    depends_on = ["azurerm_template_deployment.stats-exposer"]
}

resource "azurerm_template_deployment" "stats-exposer-github" {
    name = "stats-exposer-github"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-scm.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.stats-exposer.parameters.name}"
        repoURL = "https://github.com/noms-digital-studio/ai-stats-exposer.git"
        branch = "master"
    }

    depends_on = ["azurerm_template_deployment.stats-exposer"]
}

resource "github_repository_webhook" "stats-exposer-deploy" {
  repository = "ai-stats-exposer"

  name = "web"
  configuration {
    url = "${azurerm_template_deployment.stats-exposer-github.outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }
  active = true

  events = ["push"]
}

output "advice" {
    value = [
        "Don't forget to set up the SQL instance user/schemas manually.",
        "Application Insights continuous export must also be done manually"
    ]
}
