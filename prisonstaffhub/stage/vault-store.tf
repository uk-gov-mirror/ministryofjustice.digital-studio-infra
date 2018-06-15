
data "aws_ssm_parameter" "api-gateway-token" {
    name  = "/prisonstaffhub/stage/api_gateway_token"
}

data "aws_ssm_parameter" "api-client-secret" {
    name  = "/prisonstaffhub/stage/api_client_secret"
}

data "aws_ssm_parameter" "api-gateway-private-key" {
    name  = "/prisonstaffhub/stage/api_gateway_private_key"
}