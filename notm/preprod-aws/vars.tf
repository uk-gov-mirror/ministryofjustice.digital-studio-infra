variable "app-name" {
  type    = "string"
  default = "notm-preprod"
}

variable "tags" {
  type = "map"
  default {
    Service     = "NOTM"
    Environment = "Preprod"
  }
}

# Instance and Deployment settings
locals {
  instances = "3"
  mininstances = "2"
  instance_size = "t2.medium"
}

locals {
  api_base_endpoint           = "https://gateway.preprod.nomis-api.service.hmpps.dsd.io"
  api_endpoint_url            = "${local.api_base_endpoint}/elite2api/"
  oauth_endpoint_url          = "${local.api_base_endpoint}/auth/"
  keyworker_api_url           = "https://keyworker-api-preprod.service.hmpps.dsd.io/"
  nn_endpoint_url             = "https://notm-preprod.service.hmpps.dsd.io/"
  omic_ui_url                 = "https://omic-preprod.service.hmpps.dsd.io/"
  whereabouts_ui_url          = "https://prisonstaffhub-preprod.service.hmpps.dsd.io/whereaboutssearch"
  establishment_rollcheck_url = "https://prisonstaffhub-preprod.service.hmpps.dsd.io/establishmentroll"
  prison_staff_hub_ui_url     = "https://prisonstaffhub-preprod.service.hmpps.dsd.io/"
  api_client_id               = "elite2apiclient"
  hmpps_cookie_name           = "hmpps-session-preprod"
  hmpps_cookie_domain         = "service.hmpps.dsd.io"
  remote_auth_strategy         = "true"
}

# Azure config
locals {
  azurerm_resource_group = "notm-preprod"
  azure_region           = "ukwest"
}

# Allow list of network IPS to access this service
locals {
  allowed-list = [
    "${var.ips["office"]}/32",
    "${var.ips["quantum"]}/32",
    "${var.ips["health-kick"]}/32",
    "${var.ips["mojvpn"]}/32",
  ]
}


