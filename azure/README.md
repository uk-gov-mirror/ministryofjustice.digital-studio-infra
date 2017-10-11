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
