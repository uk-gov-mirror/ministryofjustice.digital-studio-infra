variable "app-name" {
  type    = "string"
  default = "omic-stage"
}

variable "tags" {
  type = "map"

  default {
    Service     = "omic-ui"
    Environment = "Stage"
  }
}

resource "azurerm_resource_group" "group" {
  name     = "omic-ui-stage"
  location = "ukwest"
  tags     = "${var.tags}"
}

locals {
  api_endpoint_url  = "https://gateway.t2.nomis-api.hmpps.dsd.io/elite2api/"
  api_client_id     = "omic"
  keyworker_api_url = "https://keyworker-api-stage.hmpps.dsd.io/"
  nn_endpoint_url   = "https://notm-stage.hmpps.dsd.io/"
  hmpps_cookie_name = "hmpps-session-stage"
}

locals {
  allowed-list = [
    "${var.ips["office"]}/32",
    "${var.ips["quantum"]}/32",
    "${var.ips["health-kick"]}/32",
    "${var.ips["mojvpn"]}/32",
    "82.37.105.223/32",
  ]
}
