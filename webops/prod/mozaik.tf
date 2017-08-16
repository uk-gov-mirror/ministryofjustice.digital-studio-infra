variable "mozaik_tags" {
    type = "map"
    default {
        Service = "WebOps"
        Environment = "Prod"
    }
}

resource "azurerm_template_deployment" "mozaik" {
    name = "mozaik"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice.template.json")}"
    parameters {
        name = "overwatch-mozaik"
        service = "${var.mozaik_tags["Service"]}"
        environment = "${var.mozaik_tags["Environment"]}"
        workers = "1"
    }
}

resource "azurerm_dns_cname_record" "mozaik-cname" {
    name = "overwatch-dash"
    zone_name = "service.hmpps.dsd.io"
    resource_group_name = "${azurerm_resource_group.group.name}"
    ttl = "300"
    record = "${azurerm_template_deployment.mozaik.parameters.name}.azurewebsites.net"
    tags = "${var.mozaik_tags}"
}

resource "azurerm_template_deployment" "mozaik-hostname" {
    name = "mozaik-hostname"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-hostname.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.mozaik.parameters.name}"
        hostname = "${azurerm_dns_cname_record.mozaik-cname.name}.${azurerm_dns_cname_record.mozaik-cname.zone_name}"
    }

    depends_on = ["azurerm_template_deployment.mozaik"]
}

resource "azurerm_template_deployment" "mozaik-github" {
    name = "mozaik-github"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-scm.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.mozaik.parameters.name}"
        repoURL = "https://github.com/noms-digital-studio/overwatch-mozaik.git"
        branch = "master"
    }

    depends_on = ["azurerm_template_deployment.mozaik"]
}

resource "github_repository_webhook" "mozaik-deploy" {
  repository = "overwatch-mozaik"

  name = "web"
  configuration {
    url = "${azurerm_template_deployment.mozaik-github.outputs.deployTrigger}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }
  active = true

  events = ["push"]
}
