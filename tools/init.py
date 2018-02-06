#!/usr/bin/env python3
import json
import subprocess
import sys
import os.path
import shutil

from python_modules import state_backup
from python_modules import azure_account
from python_modules import storage_creation

gitRoot = subprocess.run(
    ["git", "rev-parse", "--show-toplevel"],
    stdout=subprocess.PIPE,
    check=True
).stdout.decode().rstrip()

# Derive the backend key name from the path
cwd = os.path.basename(os.getcwd())

appDir = os.path.split(os.path.dirname(os.getcwd()))[1]

keyName = ''.join([appDir, '-', cwd, '.terraform.tfstate'])

storage_account = appDir.replace('-','') + cwd + "storage"

resource_group = appDir + "-" + cwd

storage_creation.create_storage_account(resource_group, storage_account)

# Check if this is a prod or dev environment
prodEnvs = ['prod', 'preprod']

environment = 'devtest'

if cwd in prodEnvs:
    environment = 'prod'

if not os.path.isfile("./dso.json"):
    src = ''.join([gitRoot, "/tools/config/dso.json"])
    dst = "."
    shutil.copy2(src, dst)

appEnvConfig = json.load(open("./dso.json"))

providerConfig = json.load(
    open(gitRoot + "/tools/config/azure-provider-config.json"))

if 'storage_account_name' in appEnvConfig:
    providerConfig[environment]["storage_account_name"] = appEnvConfig['storage_account_name']

if 'resource_group_name' in appEnvConfig:
    providerConfig[environment]["resource_group_name"] = appEnvConfig['resource_group_name']

configTfJson = {
    'terraform': {
        'required_version': appEnvConfig["terraform_version"],
        'backend': {
            'azurerm': {
                'resource_group_name': providerConfig[environment]["resource_group_name"],
                'storage_account_name': providerConfig[environment]["storage_account_name"],
                'container_name': 'terraform',
                'key': keyName
            }
        }
    },
    'provider': {
        'azurerm': {
            'tenant_id': providerConfig[environment]["tenant_id"],
            'subscription_id': providerConfig[environment]["subscription_id"],
            'version': appEnvConfig["azurerm_version"]
        }
    }
}

if os.path.exists("./.terraform"):
    state_backup.backup()

jsonFile = json.dumps(configTfJson, indent=2)

with open("config.tf.json", "w") as f:
    f.write(jsonFile)

config = json.load(open("./config.tf.json"))

# Ensure that CLI is logged in and can access the relevant subscription
azure_account.azure_access_token(providerConfig[environment]["subscription_id"])

# Activate relevant subscription in CLI
azure_account.azure_set_subscription(
    providerConfig[environment]["subscription_id"])

# Extract storage account key for remote state
key = subprocess.run(
    ["az", "storage", "account", "keys", "list",
        "--resource-group", providerConfig[environment]["resource_group_name"],
        "--account-name", providerConfig[environment]["storage_account_name"],
        "--query", "[0].value",
        "--output", "tsv",
     ],
    stdout=subprocess.PIPE,
    check=True
).stdout.decode()

# Init terraform with acquired storage account key
subprocess.run(
    ["terraform", "init", "-backend-config", "access_key=%s" % key],
    check=True
)
