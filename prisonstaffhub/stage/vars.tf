variable "app-name" {
  type    = "string"
  default = "prisonstaffhub-stage"
}

variable "tags" {
  type = "map"

  default {
    Service     = "prisonstaffhub"
    Environment = "Stage"
  }
}

# App settings
locals {
  api_endpoint_url    = "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/"
  api_client_id       = "elite2apiclient"
  keyworker_api_url   = "https://keyworker-api-stage.hmpps.dsd.io/"
  nn_endpoint_url     = "https://notm-stage.hmpps.dsd.io/"
  hmpps_cookie_name   = "hmpps-session-stage"
  google_analytics_id = ""
}

# Azure config
locals {
  azurerm_resource_group = "prisonstaffhub-stage"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "0.0.0.0/0",
  ]
}
