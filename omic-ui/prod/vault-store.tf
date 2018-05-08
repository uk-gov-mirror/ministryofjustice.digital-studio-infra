data "aws_ssm_parameter" "api-gateway-token" {
  name = "/${lower(var.tags["Service"])}/${lower(var.tags["Environment"])}/api_gateway_token"
}

data "aws_ssm_parameter" "api-client-secret" {
  name = "/${lower(var.tags["Service"])}/${lower(var.tags["Environment"])}/api_client_secret"
}

data "aws_ssm_parameter" "api-gateway-private-key" {
  name = "/${lower(var.tags["Service"])}/${lower(var.tags["Environment"])}/api_gateway_private_key"
}
