# Wrapper for obtaining security tokens on MFA enabled accounts.

profile=$1

if [ -z $1 ]
  then
    profile=default
fi

unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

mfa_devices=$(aws iam list-mfa-devices --profile $profile)

mfa_arn=$(echo $mfa_devices | jq -r '.MFADevices[0].SerialNumber')

echo -n "Enter MFA code: "
read mfa_code


json_result=$(aws sts get-session-token --serial-number $mfa_arn --token-code $mfa_code --profile $profile)

if [ $? -eq 0 ]; then
    echo "Session token ok"
else
    echo "Couldn't get session token"
fi

export AWS_ACCESS_KEY_ID=$(echo $json_result | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $json_result | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $json_result | jq -r '.Credentials.SessionToken')

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_SESSION_TOKEN" ]
then
  echo "FAIL: Environment variables have not been set."
else
  echo "Authentication successfully set using $profile profile."
fi
