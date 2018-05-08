data "aws_ssm_parameter" "api-gateway-token" {
  name = "/omic-ui/prod/api_gateway_token"
}

data "aws_ssm_parameter" "api-client-secret" {
  name = "/omic-ui/prod/api_client_secret"
}

data "aws_ssm_parameter" "api-gateway-private-key" {
  name = "/omic-ui/prod/api_gateway_private_key"
}
