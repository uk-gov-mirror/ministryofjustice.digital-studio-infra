
data "aws_ssm_parameter" "api-gateway-token" {
    name  = "/keyworker-api/dev/api_gateway_token"
}

data "aws_ssm_parameter" "jwt-public-key" {
    name  = "/keyworker-api/dev/jwt_public_key"
}

data "aws_ssm_parameter" "api-gateway-private-key" {
    name  = "/keyworker-api/dev/api_gateway_private_key"
}
