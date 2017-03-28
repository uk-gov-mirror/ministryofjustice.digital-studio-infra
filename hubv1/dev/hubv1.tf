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

resource "azurerm_resource_group" "hubv1-dev" {
    name = "tf_hubv1_dev"
    location = "ukwest"
    tags {
      Service = "Digital Hub version 1"
      Environment = "dev"
    }
}
