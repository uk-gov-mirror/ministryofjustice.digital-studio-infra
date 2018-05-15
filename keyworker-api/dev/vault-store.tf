data "aws_ssm_parameter" "api-gateway-token" {
  name = "/${lower(var.tags["Service"])}/${lower(var.tags["Environment"])}/api_gateway_token"
}

data "aws_ssm_parameter" "jwt-public-key" {
  name = "/${lower(var.tags["Service"])}/${lower(var.tags["Environment"])}/jwt_public_key"
}

data "aws_ssm_parameter" "api-gateway-private-key" {
  name = "/${lower(var.tags["Service"])}/${lower(var.tags["Environment"])}/api_gateway_private_key"
}

data "aws_ssm_parameter" "omic-admin-secret" {
  name = "/${lower(var.tags["Service"])}/${lower(var.tags["Environment"])}/omic_admin_secret"
}
