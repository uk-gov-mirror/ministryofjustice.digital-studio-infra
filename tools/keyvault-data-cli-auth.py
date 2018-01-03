#!/usr/bin/env python3
import json, subprocess
import sys
import os.path
import shutil

from pprint import pprint


args=json.load(sys.stdin)

vaultName = args['vault']

inputItems = args

del inputItems['vault']

def getSecrets(inputItems,vaultName):

    secrets = {}

    for key,value in inputItems.items():
        secret = subprocess.run(
        ["az", "keyvault", "secret", "show", "--vault-name",
            vaultName, "--name",value
        ],
        stdout=subprocess.PIPE, encoding='utf8',
        check=True
        ).stdout

        data = json.loads(secret)

        secrets[key] = data["value"]

    return json.dumps(secrets)
'''
config = json.load(open("./config.tf.json"))

backend = config["terraform"]["backend"]["azurerm"]
provider = config["provider"]["azurerm"]

subscription_params = ["--subscription", provider["subscription_id"]]

# Ensure that CLI is logged in and can access the relevant subscription
'''
subprocess.run(
    ["az", "account", "get-access-token"],
    check=True, stdout=subprocess.DEVNULL
)

# Activate relevant subscription in CLI
'''
subprocess.run(
    ["az", "account", "set", *subscription_params],
    check=True
)
'''
print(getSecrets(inputItems,vaultName))
