module "monitoring" {
  source = "../../aws-modules/monitoring"
  environment-name = "${local.environment_name}"
  key-pair-name = "${local.key_pair_name}"
}

locals {
  environment_name = "${var.environment-name}"
  key_pair_name = "${var.key-pair-name}"
}
