variable "rsr-name" {
    type = "string"
    default = "rsr-prod"
}

variable "env-name" {
    type = "string"
    default = "rsr-prod"
}
variable "tags" {
    type = "map"
    default {
        Service = "RSR"
        Environment = "Prod"
    }
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
    account_tier = "Standard"
    account_replication_type = "RAGRS"
    enable_blob_encryption = true

    tags = "${var.tags}"
}

resource "azurerm_key_vault" "vault" {
    name = "${var.env-name}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    location = "${azurerm_resource_group.group.location}"
    sku {
        name = "standard"
    }
    tenant_id = "${var.azure_tenant_id}"

    access_policy {
        tenant_id = "${var.azure_tenant_id}"
        object_id = "${var.azure_webops_group_oid}"
        key_permissions = []
        secret_permissions = "${var.azure_secret_permissions_all}"
    }

    access_policy {
        tenant_id = "${var.azure_tenant_id}"
        object_id = "${var.azure_app_service_oid}"
        key_permissions = []
        secret_permissions = ["get"]
    }

    access_policy {
        tenant_id = "${var.azure_tenant_id}"
        object_id = "${var.azure_jenkins_sp_oid}"
        key_permissions = []
        secret_permissions = ["set"]
    }

    enabled_for_deployment = false
    enabled_for_disk_encryption = false
    enabled_for_template_deployment = true

    tags = "${var.tags}"
}

resource "azurerm_template_deployment" "rsr" {
    name = "rsr"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice.template.json")}"
    parameters {
        name = "${var.rsr-name}"
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
        workers = "1"
        sku_name = "S1"
        sku_tier = "Standard"
    }
}

resource "azurerm_template_deployment" "rsr-hostname" {
    name = "rsr-hostname"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-hostname.template.json")}"

    parameters {
        name = "${var.rsr-name}"
        hostname = "${azurerm_dns_cname_record.rsr.name}.${azurerm_dns_cname_record.rsr.zone_name}"
    }

    depends_on = ["azurerm_template_deployment.rsr"]
}

resource "azurerm_dns_cname_record" "rsr" {
    name = "rsr"
    zone_name = "service.hmpps.dsd.io"
    resource_group_name = "webops-prod"
    ttl = "300"
    record = "${var.rsr-name}.azurewebsites.net"
    tags = "${var.tags}"
}

resource "azurerm_template_deployment" "rsr-ssl" {
    name = "rsr-ssl"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-ssl.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.rsr.parameters.name}"
        hostname = "${azurerm_dns_cname_record.rsr.name}.${azurerm_dns_cname_record.rsr.zone_name}"
        keyVaultId = "${azurerm_key_vault.vault.id}"
        keyVaultCertName = "${replace("${azurerm_dns_cname_record.rsr.name}.${azurerm_dns_cname_record.rsr.zone_name}", ".", "DOT")}"
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
    }

    depends_on = ["azurerm_template_deployment.rsr"]
}

module "slackhook-rsr" {
    source = "../../shared/modules/slackhook"
    app_name = "${azurerm_template_deployment.rsr.parameters.name}"
    channels = ["api-accelerator", "shef_changes"]
    azure_subscription = "production"
}
