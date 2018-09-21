# Overview

This folder contains scripts for setting up azure custom roles and permissions

It requires the `az` azure CLI to be used, further guides for what to do are below.

## HMPPS Azure OMS service principal

Setup scripts for the service principal used for
https://github.com/ministryofjustice/hmpps-azure-oms/

```
az role definition update --role-definition ./hmpps-azure-oms-role.json
az role assignment create --role hmpps-azure-oms-role \
  --assignee dfb01dcd-118b-40f4-8716-9c349c5189ca \
  --scope '/subscriptions/b1f3cebb-4988-4ff9-9259-f02ad7744fcb'
az role assignment create --role hmpps-azure-oms-role \
  --assignee dfb01dcd-118b-40f4-8716-9c349c5189ca \
  --scope '/subscriptions/1d95dcda-65b2-4273-81df-eb979c6b547b'
```

## App Service Deployment Reader Role

A role which allows people to see details of deployments on a web app

```
az role definition update --role-definition ./appservice-deployment-reader.json
```

## Jenkins Service Principle Role

This role sets up the minimum permissions needed by the Jenkins SP.

```
az role definition create --role-definition jenkins-dev-test-role.json
az role definition update --role-definition jenkins-dev-test-role.json
az role assignment create --role digital-studio-jenkins \
  --assignee 3ddcc102-7f43-4885-ae16-c872c65584c6 \
  --scope '/subscriptions/c27cfedb-f5e9-45e6-9642-0fad1a5c94e7'
az role assignment create --role digital-studio-jenkins \
  --assignee 3ddcc102-7f43-4885-ae16-c872c65584c6 \
  --scope '/subscriptions/9a1c1490-f6f1-4aca-aa75-17be8d7dd5fb'
```

In order to create the az role definition you will need to have owner permissions on the subscription that the role belongs to.

## Useful commands

```
az role assignment list
```

Researching avaiable permissions for a given resource, e.g keyvaults

```
az provider operation show --namespace 'Microsoft.KeyVault'
```
