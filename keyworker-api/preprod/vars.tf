variable "app-name" {
  type    = "string"
  default = "keyworker-api-preprod"
}

variable "tags" {
  type = "map"

  default {
    Service     = "keyworker-api"
    Environment = "PreProd"
  }
}

# Instance and Deployment settings
locals {
  instance_size = "t2.medium"
  instances = "3"
  mininstances = "2"
  backup_retention_period = "30"
}

locals {
  api_base_endpoint      = "https://gateway.preprod.nomis-api.service.hmpps.dsd.io"
  elite2_uri_root        = "${local.api_base_endpoint}/elite2api"
  auth_uri_root          = "${local.api_base_endpoint}/auth"
  omic_clientid          = "omicadmin"
  server_timeout         = "240000"
  azurerm_resource_group = "keyworker-api-preprod"
  azure_region           = "ukwest"
}
