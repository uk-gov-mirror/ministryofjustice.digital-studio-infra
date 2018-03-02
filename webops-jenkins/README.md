## Setup

This terraform directory sets up an azure webapp, on linux, using a docker image.  It runs this docker image, see here for details:

https://github.com/ministryofjustice/digital-studio-platform-jenkins

## Dependancies

The Jenkins setup integrates with azure AD for authentication, so in order for that to work you need to create a service principle and role and supply creds to the azureapp, see `main.tf` and `APP_SETTINGS`.  Also see instructions on the official Azure AD plugin for jenkins here:

https://wiki.jenkins.io/display/JENKINS/Azure+AD+Plugin

## Azure role for Service Principal

See the README in digital-studio-infra/azure.

## Jenkins Service Principle

Use the following command to create an Azure Service Principal.

```az ad sp create-for-rbac -n "digital-studio-webops-jenkins-dev" \
  --role contributor \
  --scopes /subscriptions/c27cfedb-f5e9-45e6-9642-0fad1a5c94e7/resourceGroups/webops \
  --role digital-studio-jenkins```

Once the service principal has been created it will be listed in Azure Active Directory/App registrations. It will need the following settings:

1. Set up the following return URL’s

  ```https://localhost:8080/securityRealm/finishLogin```  for local testing

  ```https://<app-dns-name>/securityRealm/finishLogin```  for live login

  ```<app-dns-name>``` = app DNS CNAME e.g. webops-jenkins-prod.service.hmpps.dsd.io

2. In Required Permissions add the following to Windows Azure Active Directory (elevated permissions are required for this step):

  - Application Permissions: Read directory data
  - Delegated Permissions: Sign in and read user profile

  After saving the permissions you will also need to click the Grant Permissions button for them to take effect.

3.  Under Keys create a new key called 'jenkins' , copy the value (it will only be shown once), it will be used as Client Secret (azure-sp-secret) in the key vault created by Terraform - see below.

## Key Vault

Terraform will create a key vault for this app however in order to complete the key vault will need the following secrets. This is currently a manual step:

- azure-sp-clientid: the id of the service principal
- azure-sp-secret: The jenkins secret created above
- azure-oauth-clientid: Same as  azure-sp-clientid
- azure-oauth-secret: Same as azure-sp-secret
- github-deploy-key: From ministryofjustice/digital-studio-platform-pipelines

The application will also need an SSL certificate which can be created using tools/azure-letsencrypt-cli-auth.py.

This will create a secret in the key vault that contains the SSL certificate.

After these have been set Terraform can be run again.

### Some helpful things about running a docker container inside an azure app services....

---
App deployment webhook, so when an image in pushed to docker hub it will auto pull and deploy the new image in azure:

```bash
az webapp deployment container show-cd-url -n webops-jenkins-dev -g webops-jenkins-dev --query CI_CD_URL
```
---
Show which container is currently set to run
```bash
az webapp config container show --resource-group webops-jenkins-dev --name webops-jenkins-dev
```
---
Set the container
```bash
az webapp config container set --resource-group webops-jenkins-dev --name mw-test-app --docker-custom-image-name [repo/image:tag]
```
---
Tail the stdout from your running container, this requires *Docker container logging* switched on in the azure portal, or via the ARM template see `"httpLoggingEnabled": true`
```bash
az webapp log tail --name webops-jenkins-dev -g webops-jenkins-dev
```
Note, this is really useful to see what *docker* command azure use to spin up the container.

---
See the logs via KUDU, follow the link to the latest logs.
https://webops-jenkins-dev.scm.azurewebsites.net/api/logs/docker

---
