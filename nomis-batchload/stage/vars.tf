variable "app-name" {
  type    = "string"
  default = "nomis-batchload-stage"
}

variable "tags" {
  type = "map"

  default {
    Service     = "Nomis Batchload"
    Environment = "Stage"
  }
}

# Instance and Deployment settings
locals {
  instances = "2"
  mininstances = "1"
  db_multi_az = "false"
  db_backup_retention_period = "0"
  db_maintenance_window = "Mon:00:00-Sun:11:59"
  db_apply_immediately = "true"
}

# App settings
locals {
  nomis_api_url       = "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api"
  nomis_auth_url      = "https://gateway.t3.nomis-api.hmpps.dsd.io/auth"
  api_client_id       = "batchadmin"
  domain              = "https://licences-stage.hmpps.dsd.io"
}

# Azure config
locals {
  azurerm_resource_group = "nomis-batchload-stage"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "0.0.0.0/0",
  ]
}
