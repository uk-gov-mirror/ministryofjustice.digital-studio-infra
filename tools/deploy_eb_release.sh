#!/usr/bin/env bash

set -e

VERSION=$3
ENV=$2
APP=$1
DEVTEST_S3_BUCKET="elasticbeanstalk-eu-west-2-429061350814"
PROD_S3_BUCKET="elasticbeanstalk-eu-west-2-589133037702"

display_usage() {
  echo -e "\nUsage: $0 [mock|stage|preprod|prod] [version]\n"
}

deploy_to_devtest() {
  # Build a deployment file
  generate_version_json ${APP} ${VERSION}
  echo $APP_VERSION_JSON | aws s3 cp - s3://${DEVTEST_S3_BUCKET}/${APP}/${VERSION}.json 
  aws elasticbeanstalk create-application-version --application-name="${APP}" --version-label="${VERSION}" --source-bundle="{\"S3Bucket\": \"${DEVTEST_S3_BUCKET}\",\"S3Key\": \"${APP}/${VERSION}.json\"}"
  #aws elasticbeanstalk update-environment --environment-name ${APP}-${ENV} --version-label ${VERSION}
}

promote_to_preprod() {
  echo "Promoting release to preprod"
  aws s3 cp s3://${DEVTEST_S3_BUCKET}/${APP}/${VERSION}.json s3://${PROD_S3_BUCKET}/${APP}/${VERSION}.json
  aws elasticbeanstalk create-application-version --application-name="${APP}" --version-label="${VERSION}" --source-bundle="{\"S3Bucket\": \"${DEVTEST_S3_BUCKET}\",\"S3Key\": \"${APP}/${VERSION}.json\"}"
  aws elasticbeanstalk update-environment --environment-name ${APP}-${ENV} --version-label ${VERSION}
}

promote_to_prod() {
  echo "Promoting release to prod"
  aws elasticbeanstalk update-environment --environment-name ${APP}-${ENV} --version-label ${VERSION}
}

generate_version_json() {
  # This is a hack to cover the different container ports used by each
  # app we should standardise the port.
  case "$APP" in
    ("keyworker-api") containerport="8080" ;;
    ("licences-pdf") containerport="8080" ;;
    (*) containerport="3000" ;;
  esac  

  APP_VERSION_JSON="
{
  \"AWSEBDockerrunVersion\": \"1\",
  \"Image\": {
    \"Name\": \"mojdigitalstudio/${APP}:${VERSION}\",
    \"Update\": \"true\"
  },
  \"Ports\": [
    {\"ContainerPort\": \"${containerport}\"}
  ]
}\"
"

}

# if less than three arguments supplied, display usage
if [  $# -le 2 ]
then
  display_usage
  exit 1
fi

# check whether user had supplied -h or --help . If yes display usage
if [[ ( $# == "--help") ||  $# == "-h" ]]
then
  display_usage
  exit 0
fi

if [[ "$ENV" =~ ^(dev|mock|stage)$ ]]; then
    echo "Deploying: APP=${APP}, ENV=${ENV}, VERSION=${VERSION}"
    deploy_to_devtest ${VERSION} ${ENV} ${VERSION}
elif [[ "$ENV" =~ ^(preprod)$ ]]; then
    echo "Deploying: APP=${APP}, ENV=${ENV}, VERSION=${VERSION}"
    promote_to_preprod ${VERSION} ${ENV} ${VERSION}    
elif [[ "$ENV" =~ ^(prod)$ ]]; then
    echo "Deploying: APP=${APP}, ENV=${ENV}, VERSION=${VERSION}"
    promote_to_prod ${VERSION} ${ENV} ${VERSION}
else
    echo "$ENV is not a valid environment"
fi

