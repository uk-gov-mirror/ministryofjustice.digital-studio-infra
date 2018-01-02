#!/usr/bin/env python3
import json, subprocess
import sys
import os.path
import shutil

from pprint import pprint

from jinja2 import Environment, FileSystemLoader

gitRoot = subprocess.run(
    ["git", "rev-parse", "--show-toplevel"],
    stdout=subprocess.PIPE, encoding='utf8',
    check=True
).stdout.rstrip()

templatePath = os.path.join(gitRoot, 'tools', 'templates')

j2_env = Environment(loader=FileSystemLoader(templatePath))

cwd = os.path.basename(os.getcwd())

appDir = os.path.split(os.path.dirname(os.getcwd()))[1]

prodEnvs = ['prod','preprod']

environment = 'dev'

if cwd in prodEnvs:
    environment = 'prod'

templateFile = ''.join(['common-' , environment , '.jinja'])

template = j2_env.get_template(templateFile)

keyName = ''.join([appDir , '-' , environment])

if not os.path.isfile("./azure.json"):
    src = ''.join([gitRoot,"/tools/templates/azure.json"])
    dst = "."
    shutil.copy2(src,dst)

providerConfig = json.load(open("./azure.json"))

rendered_file = template.render(key_name=keyName,terraform_version=providerConfig["terraform_version"],azurerm_version=providerConfig["azurerm_version"])

with open("config.tf.json", "w") as f:
    f.write(rendered_file)

config = json.load(open("./config.tf.json"))

backend = config["terraform"]["backend"]["azurerm"]
provider = config["provider"]["azurerm"]

subscription_params = ["--subscription", provider["subscription_id"]]

# Ensure that CLI is logged in and can access the relevant subscription
subprocess.run(
    ["az", "account", "get-access-token", *subscription_params],
    check=True, stdout=subprocess.DEVNULL
)

# Activate relevant subscription in CLI
subprocess.run(
    ["az", "account", "set", *subscription_params],
    check=True
)

# Extract storage account key for remote state
key = subprocess.run(
    ["az", "storage", "account", "keys", "list",
        "--resource-group", backend["resource_group_name"],
        "--account-name", backend["storage_account_name"],
        "--query", "[0].value",
        "--output", "tsv",
    ],
    stdout=subprocess.PIPE, encoding='utf8',
    check=True
).stdout

# Init terraform with acquired storage account key
subprocess.run(
    ["terraform", "init", "-backend-config", "access_key=%s" % key],
    check=True
)
