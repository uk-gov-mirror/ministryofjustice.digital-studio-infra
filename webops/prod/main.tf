terraform {
    required_version = ">= 0.9.0"
    backend "azure" {
        resource_group_name = "webops-prod"
        storage_account_name = "nomsstudiowebopsprod"
        container_name = "terraform"
        key = "webops-prod.terraform.tfstate"
        arm_subscription_id = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
        arm_tenant_id = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
    }
}

variable "tags" {
    type = "map"
    default {
        Service = "WebOps"
        Environment = "Management"
    }
}

resource "azurerm_resource_group" "group" {
  name = "webops-prod"
  location = "ukwest"
  tags = "${var.tags}"
}

resource "azurerm_key_vault" "vault" {
    name = "webops-prod"
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
        key_permissions = []
        secret_permissions = ["get", "set"]
    }
    access_policy {
        object_id = "${var.slackhook_app_oid}"
        tenant_id = "${var.azure_tenant_id}"
        key_permissions = []
        secret_permissions = ["get"]
    }

    enabled_for_deployment = false
    enabled_for_disk_encryption = false
    enabled_for_template_deployment = true

    tags = "${var.tags}"

}
