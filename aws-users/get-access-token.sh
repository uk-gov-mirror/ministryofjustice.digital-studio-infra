#!/bin/bash

# Wrapper for obtaining security tokens on MFA enabled accounts.

accountid=$1
username=$2

read -p "Enter MFA code: " mfa_code

unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

echo "serial number: arn:aws:iam::$accountid:mfa/$username"

json_result=$(aws sts get-session-token --serial-number arn:aws:iam::$accountid:mfa/$username --token-code $mfa_code)

echo $json_result

export AWS_ACCESS_KEY_ID=$(echo $json_result | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $json_result | jq -r '.Credentials.SecretAccessKey')
export AWS_SECURITY_TOKEN=$(echo $json_result | jq -r '.Credentials.SessionToken')
