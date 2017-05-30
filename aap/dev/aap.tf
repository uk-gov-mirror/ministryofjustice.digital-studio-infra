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

variable "env-name" {
    type = "string"
    default = "aap-dev"
}
variable "viper-name" {
    type = "string"
    default = "viper-dev"
}
variable "rsr-name" {
    type = "string"
    default = "rsr-dev"
}
variable "tags" {
    type = "map"
    default {
        Service = "AAP"
        Environment = "Dev"
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
    firewall_rules = [
        {
            label = "Allow azure access"
            start = "0.0.0.0"
            end = "0.0.0.0"
        },
        {
            label = "Open to the world"
            start = "0.0.0.0"
            end = "255.255.255.255"
        },
    ]
    audit_storage_account = "${azurerm_storage_account.storage.name}"
    edition = "Basic"
    collation = "SQL_Latin1_General_CP1_CI_AS"
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

resource "azurerm_template_deployment" "viper-ssl" {
    name = "viper-ssl"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-sslonly.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.viper.parameters.name}"
    }

    depends_on = ["azurerm_template_deployment.viper"]
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

resource "github_repository_webhook" "viper-deploy" {
  repository = "viper-service"

  name = "web"
  configuration {
    url = "${azurerm_template_deployment.viper-github.outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }
  active = true

  events = ["push"]
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
    name = "${var.rsr-name}"
    zone_name = "hmpps.dsd.io"
    resource_group_name = "webops"
    ttl = "300"
    record = "${var.rsr-name}.azurewebsites.net"
    tags = "${var.tags}"
}

resource "azurerm_template_deployment" "rsr-github" {
    name = "rsr-github"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-scm.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.rsr.parameters.name}"
        repoURL = "https://github.com/noms-digital-studio/rsr-calculator-service.git"
        branch = "master"
    }

    depends_on = ["azurerm_template_deployment.rsr"]
}

resource "github_repository_webhook" "rsr-deploy" {
  repository = "rsr-calculator-service"

  name = "web"
  configuration {
    url = "${azurerm_template_deployment.rsr-github.outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }
  active = true

  events = ["push"]
}
