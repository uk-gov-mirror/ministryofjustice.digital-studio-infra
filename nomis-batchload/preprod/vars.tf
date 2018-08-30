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
  instances = "1"
  mininstances = "1"
}

# App settings
locals {
  nomis_api_url       = "https://gateway.preprod.nomis-api.service.hmpps.dsd.io/elite2api/api"
  api_client_id       = "batchadmin"
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
