variable "app-name" {
  type    = "string"
  default = "keyworker-api-dev"
}

variable "tags" {
  type = "map"

  default {
    Service     = "keyworker-api"
    Environment = "Dev"
  }
}

locals {
  elite2_uri_root = "https://noms-api-dev.dsd.io/elite2api"
}
