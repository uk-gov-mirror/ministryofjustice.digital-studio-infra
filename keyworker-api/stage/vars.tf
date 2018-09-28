variable "app-name" {
  type    = "string"
  default = "keyworker-api-stage"
}

variable "tags" {
  type = "map"

  default {
    Service     = "keyworker-api"
    Environment = "Stage"
  }
}

# Instance and Deployment settings
locals {
  instances = "2"
  mininstances = "1"
  backup_retention_period = "0"
}

locals {
  api_base_endpoint      = "https://gateway.t2.nomis-api.hmpps.dsd.io"
  elite2_uri_root        = "${local.api_base_endpoint}/elite2api"
  auth_uri_root          = "${local.api_base_endpoint}/auth"
  omic_clientid          = "omicadmin"
  server_timeout         = "180000"
  azurerm_resource_group = "keyworker-api-stage"
  azure_region           = "ukwest"
}
