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

# Instance and Deployment settings
locals {
  instances = "2"
  mininstances = "1"
  instance_size = "t2.micro"
}

# App settings
locals {
  api_base_endpoint   = "https://gateway.t2.nomis-api.hmpps.dsd.io"
  api_endpoint_url    = "${local.api_base_endpoint}/elite2api/"
  oauth_endpoint_url   = "${local.api_base_endpoint}/auth/"
  api_client_id       = "elite2apiclient"
  keyworker_api_url   = "https://keyworker-api-stage.hmpps.dsd.io/"
  nn_endpoint_url     = "https://notm-stage.hmpps.dsd.io/"
  omic_ui_url         = "https://omic-stage.hmpps.dsd.io/"
  hmpps_cookie_name   = "hmpps-session-stage"
  google_analytics_id = ""
  maintain_roles_enabled = "true"
  keyworker_profile_stats_enabled = "true"
  keyworker_dashboard_stats_enabled = "true"
}

# Azure config
locals {
  azurerm_resource_group = "omic-ui-stage"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "0.0.0.0/0",
  ]
}
