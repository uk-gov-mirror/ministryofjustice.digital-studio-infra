variable "app-name" {
  type    = "string"
  default = "nomis-batchload-prod"
}

variable "tags" {
  type = "map"

  default {
    Service     = "Nomis Batchload"
    Environment = "Prod"
  }
}

# Instance and Deployment settings
locals {
  instance_size = "t2.medium"
  instances = "3"
  mininstances = "2"
  db_multi_az = "false"
  db_backup_retention_period = "0"
  db_maintenance_window = "Mon:00:00-Sun:11:59"
  db_apply_immediately = "true"
}

# App settings
locals {
  nomis_api_url       = "https://gateway.prod.nomis-api.service.hmpps.dsd.io/elite2api/api"
  api_client_id       = "batchadmin"
}

# Azure config
locals {
  azurerm_resource_group = "nomis-batchload-prod"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "${var.ips["office"]}/32",
    "${var.ips["quantum"]}/32",
    "${var.ips["health-kick"]}/32",
    "${var.ips["mojvpn"]}/32",
  ]
}
