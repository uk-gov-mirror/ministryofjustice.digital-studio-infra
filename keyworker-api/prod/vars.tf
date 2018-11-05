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
  instance_size = "t2.medium"
  instances = "3"
  mininstances = "3"
  backup_retention_period = "30"
}

locals {
  api_base_endpoint      = "https://gateway.nomis-api.service.justice.gov.uk"
  elite2_uri_root        = "${local.api_base_endpoint}/elite2api"
  auth_uri_root          = "${local.api_base_endpoint}/auth"
  omic_clientid          = "omicadmin"
  server_timeout         = "180000"
  azurerm_resource_group = "keyworker-api-prod"
  azure_region           = "ukwest"
}
