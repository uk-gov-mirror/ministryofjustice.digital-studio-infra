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

resource "random_id" "sql-app-password" {
    byte_length = 32
}

resource "azurerm_resource_group" "group" {
    name = "${var.env-name}"
    location = "ukwest"
    tags = "${var.tags}"
}

resource "azurerm_storage_account" "storage" {
    name = "${replace(var.env-name, "-", "")}storage"
    resource_group_name = "${azurerm_resource_group.group.name}"
    location = "${azurerm_resource_group.group.location}"
    account_type = "Standard_RAGRS"
    enable_blob_encryption = true

    tags = "${var.tags}"
}

module "sql" {
    source = "../../shared/modules/azure-sql"
    name = "${var.env-name}"
    resource_group = "${azurerm_resource_group.group.name}"
    location = "${azurerm_resource_group.group.location}"
    administrator_login = "aap"
    firewall_rules = []
    audit_storage_account = "${azurerm_storage_account.storage.name}"
    edition = "Standard"
    collation = "SQL_Latin1_General_CP1_CI_AS"
    tags = "${var.tags}"

    # Use `terraform taint -module sql null_resource.db-setup` to rerun
    setup_queries = [
<<SQL
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'app')
    ALTER USER app WITH PASSWORD = '${random_id.sql-app-password.b64}';
ELSE
    CREATE USER app WITH PASSWORD = '${random_id.sql-app-password.b64}';
SQL
,
        "GRANT SELECT TO app"
    ]
}

resource "azurerm_template_deployment" "api" {
    name = "api"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/api-management.template.json")}"

    parameters {
        name = "${var.env-name}"
        publisherEmail = "noms-studio-webops@digital.justice.gov.uk"
        publisherName = "HMPPS"
        sku = "Developer"
    }
}
