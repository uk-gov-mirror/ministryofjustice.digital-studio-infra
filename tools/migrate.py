#!/usr/bin/env python3
import json
import subprocess
import sys
import os.path
import shutil
import time

prodEnvs = ['prod', 'preprod']

cwd = os.path.basename(os.getcwd())
appDir = os.path.split(os.path.dirname(os.getcwd()))[1]
resourceGroup = appDir+"-"+cwd

if cwd in prodEnvs:
  newStorageAccount = appDir + "prod" + "storage"
else:
  newStorageAccount = appDir + "storage"

config = json.load(open("config.tf.json"))

stateKey = config['terraform']['backend']['azurerm']['key']
subscriptionId = config['provider']['azurerm']['subscription_id']
currentStorageAccount = config['terraform']['backend']['azurerm']['storage_account_name']

if newStorageAccount == currentStorageAccount:
  print("No storage account name change required")
else:
  print("Changing storage account name from " + currentStorageAccount + " to " + newStorageAccount + " based on current working directory")
  
subprocess.run(
    ["az", "account", "get-access-token"]
)

subprocess.run(
	["az", "account", "set",
	"--subscription", subscriptionId
	],
	stdout=subprocess.PIPE,
	check=True
).stdout.decode()

print("step 1")
accounts = json.loads(subprocess.run(
    ["az", "storage", "account", "list"],
    stdout=subprocess.PIPE,
    check=True
).stdout.decode())

names = []

for name in accounts:
  names.append(name['name'])

if newStorageAccount in names: 
  subprocess.run(
      ["az", "storage", "account", "create",
      "--name", newStorageAccount,
      "--resource-group", resourceGroup,
      ],
      stdout=subprocess.PIPE,
      check=True
  ).stdout.decode()
else:
  print(newStorageAccount + " - account name already exists")

config['terraform']['backend']['azurerm']['storage_account_name'] = newStorageAccount

# NB, this assumes we have resource group names following the format of {product}-{env} precreated, which _does_ seem to be true
config['terraform']['backend']['azurerm']['resource_group_name'] = resourceGroup

with open('config.tf.json', 'w') as outfile:
    json.dump(config, outfile, indent=4) 