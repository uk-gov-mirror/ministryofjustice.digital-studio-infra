variable "app-name" {
  type    = "string"
  default = "keyworker-api-prod"
}

variable "tags" {
  type = "map"

  default {
    Service     = "keyworker-api"
    Environment = "Prod"
  }
}

# Instance and Deployment settings
locals {
  instances = "2"
  mininstances = "1"
  backup_retention_period = "30"
}

locals {
  elite2_uri_root        = "https://gateway.nomis-api.service.justice.gov.uk/elite2api"
  omic_clientid          = "omicadmin"
  server_timeout         = "180000"
  azurerm_resource_group = "keyworker-api-prod"
  azure_region           = "ukwest"
}
