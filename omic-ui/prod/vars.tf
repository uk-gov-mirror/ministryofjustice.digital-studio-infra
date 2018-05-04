variable "app-name" {
  type    = "string"
  default = "omic-prod"
}

variable "tags" {
  type = "map"

  default {
    Service     = "omic-ui"
    Environment = "Prod"
  }
}

resource "azurerm_resource_group" "group" {
  name     = "omic-ui-prod"
  location = "ukwest"
  tags     = "${var.tags}"
}

locals {
  api_endpoint_url  = "https://gateway.nomis-api.service.justice.gov.uk/elite2api/"
  api_client_id     = "elite2apiclient"
  keyworker_api_url = "https://keyworker-api.service.hmpps.dsd.io/"
  nn_endpoint_url   = "https://notm.service.hmpps.dsd.io/"
  hmpps_cookie_name = "hmpps-session-prod"
}

locals {
  allowed-list = [
    "${var.ips["office"]}/32",
    "${var.ips["quantum"]}/32",
    "${var.ips["health-kick"]}/32",
    "${var.ips["mojvpn"]}/32",
  ]
}
