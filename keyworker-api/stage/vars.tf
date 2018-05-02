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

locals {
  elite2_api_uri_root = "https://gateway.t2.nomis-api.hmpps.dsd.io/elite2api/api"
}
