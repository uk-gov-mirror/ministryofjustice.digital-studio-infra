variable "app" {
  type    = "string"
  default = "offloc"
}

variable "env" {
  type    = "string"
  default = "stage"
}

variable "storage" {
  type    = "string"
  default = "offlocstagestorage"
}

variable "deployment-channels" {
  type    = "list"
  default = ["offloc-replacement"]
}

locals {
  name  = "${var.app}-${var.env}"
  cname = "${local.name}"

  github_deploy_branch = "deploy-to-${var.env}"

  app_team_oid = "${local.azure_offloc_group_oid}"

  tags {
    Service     = "${var.app}"
    Environment = "${var.env}"
  }
}
