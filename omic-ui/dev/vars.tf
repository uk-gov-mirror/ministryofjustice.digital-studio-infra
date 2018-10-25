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

# Instance and Deployment settings
locals {
  instances = "1"
  mininstances = "0"
}

# App settings
locals {
  api_base_endpoint   = "https://gateway.t3.nomis-api.hmpps.dsd.io"
  api_endpoint_url    = "${local.api_base_endpoint}/elite2api/"
  oauth_endpoint_url   = "${local.api_base_endpoint}/auth/"
  api_client_id       = "elite2apiclient"
  keyworker_api_url   = "https://keyworker-api-dev.hmpps.dsd.io/"
  nn_endpoint_url     = "https://notm-dev.hmpps.dsd.io/"
  hmpps_cookie_name   = "hmpps-session-dev"
  google_analytics_id = "UA-106741063-1"
  maintain_roles_enabled = "true"
  keyworker_profile_stats_enabled = "true"
}

# Azure config
locals {
  azurerm_resource_group = "omic-ui-dev"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "0.0.0.0/0",
  ]
}
