variable "app-name" {
  type    = "string"
  default = "omic-dev"
}

variable "tags" {
  type = "map"

  default {
    Service     = "omic-ui"
    Environment = "Dev"
  }
}

resource "azurerm_resource_group" "group" {
  name     = "omic-ui-dev"
  location = "ukwest"
  tags     = "${var.tags}"
}

locals {
  api_endpoint_url  = "https://noms-api-dev.dsd.io/elite2api/"
  api_client_id     = "elite2apiclient"
  keyworker_api_url = "https://keyworker-api-dev.hmpps.dsd.io/"
  nn_endpoint_url   = "https://notm-dev.hmpps.dsd.io/"
  hmpps_cookie_name = "hmpps-session-dev"
}
