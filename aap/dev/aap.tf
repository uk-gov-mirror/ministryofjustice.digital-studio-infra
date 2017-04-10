terraform {
    required_version = ">= 0.9.2"
    backend "azure" {
        resource_group_name = "webops"
        storage_account_name = "nomsstudiowebops"
        container_name = "terraform"
        key = "aap-dev.terraform.tfstate"
        arm_subscription_id = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
        arm_tenant_id = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
    }
}

variable "viper-name" {
    type = "string"
    default = "viper-dev"
}
variable "tags" {
    type = "map"
    default {
        Service = "AAP"
        Environment = "Dev"
    }
}

resource "azurerm_resource_group" "group" {
    name = "aap-dev"
    location = "ukwest"
    tags = "${var.tags}"
}

resource "azurerm_template_deployment" "viper" {
    name = "viper"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice.template.json")}"
    parameters {
        name = "${var.viper-name}"
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
    }
}

resource "azurerm_template_deployment" "viper-hostname" {
    name = "viper-hostname"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-hostname.template.json")}"

    parameters {
        name = "${var.viper-name}"
        hostname = "${azurerm_dns_cname_record.viper.name}.${azurerm_dns_cname_record.viper.zone_name}"
    }

    depends_on = ["azurerm_template_deployment.viper"]
}

resource "azurerm_dns_cname_record" "viper" {
    name = "${var.viper-name}"
    zone_name = "hmpps.dsd.io"
    resource_group_name = "webops"
    ttl = "300"
    record = "${var.viper-name}.azurewebsites.net"
    tags = "${var.tags}"
}

resource "azurerm_template_deployment" "viper-github" {
    name = "viper-github"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-scm.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.viper.parameters.name}"
        repoURL = "https://github.com/noms-digital-studio/viper-service.git"
        branch = "master"
    }

    depends_on = ["azurerm_template_deployment.viper"]
}
