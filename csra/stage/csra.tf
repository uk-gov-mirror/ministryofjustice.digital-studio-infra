terraform {
    required_version = ">= 0.9.2"
    backend "azure" {
        resource_group_name = "webops"
        storage_account_name = "nomsstudiowebops"
        container_name = "terraform"
        key = "csra-stage.terraform.tfstate"
        arm_subscription_id = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
        arm_tenant_id = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
    }
}

variable "app-name" {
    type = "string"
    default = "csra-stage"
}
variable "tags" {
    type = "map"
    default {
        Service = "CSRA"
        Environment = "Stage"
    }
}

resource "azurerm_resource_group" "group" {
    name = "${var.app-name}"
    location = "ukwest"
    tags = "${var.tags}"
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

resource "azurerm_template_deployment" "webapp-hostname" {
    name = "webapp-hostname"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-hostname.template.json")}"

    parameters {
        name = "${var.app-name}"
        hostname = "${azurerm_dns_cname_record.cname.name}.${azurerm_dns_cname_record.cname.zone_name}"
    }

    depends_on = ["azurerm_template_deployment.webapp"]
}

resource "azurerm_template_deployment" "webapp-github" {
    name = "webapp-github"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-scm.template.json")}"

    parameters {
        name = "${var.app-name}"
        repoURL = "https://github.com/noms-digital-studio/csra-app.git"
        branch = "deploy-to-stage"
    }

    depends_on = ["azurerm_template_deployment.webapp"]
}


resource "github_repository_webhook" "webapp-deploy" {
  repository = "csra-app"

  name = "web"
  configuration {
    url = "${azurerm_template_deployment.webapp-github.outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }
  active = true

  events = ["push"]
}

resource "azurerm_dns_cname_record" "cname" {
    name = "${var.app-name}"
    zone_name = "hmpps.dsd.io"
    resource_group_name = "webops"
    ttl = "300"
    record = "${var.app-name}.azurewebsites.net"
    tags = "${var.tags}"
}

# The "production" site currently uses this non-production DNS entry
# which can only be configured via the non-prod subscription
# it's due to move to .service.hmpps.dsd.io
resource "azurerm_dns_cname_record" "cname-prod" {
    name = "csra"
    zone_name = "noms.dsd.io"
    resource_group_name = "webops"
    ttl = "300"
    record = "csra-prod.azurewebsites.net"
    tags = {
        Service = "CSRA"
        Environment = "Prod"
    }
}
