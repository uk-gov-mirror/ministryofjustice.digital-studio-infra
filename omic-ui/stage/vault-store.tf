
data "aws_ssm_parameter" "api-gateway-token" {
    name  = "/omic-ui/stage/api_gateway_token"
}

data "aws_ssm_parameter" "api-client-secret" {
    name  = "/omic-ui/stage/api_client_secret"
}

data "aws_ssm_parameter" "api-gateway-private-key" {
    name  = "/omic-ui/stage/api_gateway_private_key"
}
