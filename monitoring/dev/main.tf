module "monitoring" {
  source = "../../aws-modules/monitoring"
  environment-name = "${local.environment_name}"
  key-pair-name = "${local.key_pair_name}"
  application-name = "${local.application_name}"
}

locals {
  environment_name = "${var.environment-name}"
  key_pair_name = "${var.key-pair-name}"
  application_name = "${var.application-name}"
}
