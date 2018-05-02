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

locals {
    elite2_api_uri_root  = "https://gateway.preprod.nomis-api.service.hmpps.dsd.io/elite2api/api"
  }
