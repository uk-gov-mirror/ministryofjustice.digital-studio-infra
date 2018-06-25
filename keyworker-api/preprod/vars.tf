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
  instances = "1"
  mininstances = "1"
}

locals {
  elite2_uri_root        = "https://gateway.preprod.nomis-api.service.hmpps.dsd.io/elite2api"
  omic_clientid          = "omicadmin"
  server_timeout         = "240000"
  azurerm_resource_group = "keyworker-api-preprod"
  azure_region           = "ukwest"
}
