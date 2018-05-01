variable "app" {
  type    = "string"
  default = "offloc"
}

variable "env" {
  type    = "string"
  default = "prod"
}

variable "deployment-channels" {
  type    = "list"
  default = ["offloc-replacement", "shef_changes"]
}

locals {
  name    = "${var.app}-${var.env}"
  storage = "${var.app}${var.env}storage"
  cname   = "${var.app}"

  github_deploy_branch = ""

  app_team_oid = "${local.azure_empty_group_oid}"

  tags {
    Service     = "${var.app}"
    Environment = "${var.env}"
  }
}
