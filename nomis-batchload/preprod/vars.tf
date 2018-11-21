variable "app-name" {
  type    = "string"
  default = "nomis-batchload-preprod"
}

variable "tags" {
  type = "map"

  default {
    Service     = "Nomis Batchload"
    Environment = "PreProd"
  }
}

# Instance and Deployment settings
locals {
  instance_size = "t2.medium"
  instances = "1"
  mininstances = "1"
  db_multi_az = "false"
  db_backup_retention_period = "0"
  db_maintenance_window = "Mon:00:00-Sun:11:59"
  db_apply_immediately = "true"
}

# App settings
locals {
  nomis_api_url       = "https://gateway.preprod.nomis-api.service.hmpps.dsd.io/elite2api/api"
  nomis_auth_url      = "https://gateway.preprod.nomis-api.service.hmpps.dsd.io/auth"
  api_client_id       = "batchadmin"
  domain              = "https://licences-preprod.hmpps.dsd.io"
  findnomisid_interval_millis   = "200"
  sendrelation_interval_millis  = "200"
  response_timeout              = "35000"
  deadline_timeout              = "45000"
}

# Azure config
locals {
  azurerm_resource_group = "nomis-batchload-preprod"
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
