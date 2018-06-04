variable "app-name" {
  type    = "string"
  default = "prisonstaffhub-dev"
}

variable "tags" {
  type = "map"

  default {
    Service     = "prisonstaffhub"
    Environment = "Dev"
  }
}

# App settings
locals {
  api_endpoint_url    = "https://noms-api-dev.dsd.io/elite2api/"
  api_client_id       = "elite2apiclient"
  keyworker_api_url   = "https://keyworker-api-dev.hmpps.dsd.io/"
  nn_endpoint_url     = "https://notm-dev.hmpps.dsd.io/"
  hmpps_cookie_name   = "hmpps-session-dev"
  google_analytics_id = "UA-106741063-1"
}

# Azure config
locals {
  azurerm_resource_group = "prisonstaffhub-dev"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "0.0.0.0/0",
  ]
}
