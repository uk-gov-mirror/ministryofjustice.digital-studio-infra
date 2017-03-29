terraform {
    required_version = ">= 0.9.0"
    backend "azure" {
        resource_group_name = "webops"
        storage_account_name = "nomsstudiowebops"
        container_name = "terraform"
        key = "hubv1-dev.terraform.tfstate"
        arm_subscription_id = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
        arm_tenant_id = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
    }
}

variable "tags" {
    type = "map"
    default {
        Service = "Digital Hub v1"
        Environment = "dev"
    }
}

resource "azurerm_resource_group" "hubv1-dev" {
    name = "hmpps-hubv1-dev"
    location = "ukwest"
    tags = "${var.tags}"
}

resource "azurerm_template_deployment" "hmpps-hubv1-webapp" {
    name = "hmpps-hubv1-dev"
    resource_group_name = "${azurerm_resource_group.hubv1-dev.name}"
    deployment_mode = "Incremental"
    template_body = "${file("./webapp.template.json")}"
    parameters {
        name = "hmpps-hubv1-dev"
        hostingEnvironment = ""
        hostingPlanName = "hmpps-hubv1-dev"
        location = "UK West"
        sku = "Free"
        workerSize = "0"
        serverFarmResourceGroup = "hmpps-hubv1-dev"
        skuCode = "F1"
        subscriptionId = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
    }
}
