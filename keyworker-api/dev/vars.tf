variable "app-name" {
  type    = "string"
  default = "keyworker-api-dev"
}

variable "tags" {
  type = "map"

  default {
    Service     = "keyworker-api"
    Environment = "Dev"
  }
}

# Instance and Deployment settings
locals {
  instances = "1"
  mininstances = "0"
  backup_retention_period = "0"
}

locals {
  api_base_endpoint      = "https://gateway.t3.nomis-api.hmpps.dsd.io"
  elite2_uri_root        = "${local.api_base_endpoint}/elite2api"
  auth_uri_root          = "${local.api_base_endpoint}/auth"
  omic_clientid          = "omicadmin"
  server_timeout         = "60000"
  azurerm_resource_group = "keyworker-api-dev"
  azure_region           = "ukwest"
}
