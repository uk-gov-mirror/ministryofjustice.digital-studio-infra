variable "environment-name" {
    type = "string"
    default = "dev"
}

variable "application-name" {
  default = "monitoring"
}

variable "key-pair-name" {
   default =   "cw_dev"
}

variable "dns-zone-name" {
  default = "service.hmpps.dsd.io"
}

variable "dns-zone-rg" {
  default = "webops-prod"
 }