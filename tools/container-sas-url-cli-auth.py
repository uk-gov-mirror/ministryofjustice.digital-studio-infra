#!/usr/bin/env python3

#  Terraform external data source for generating a storage SAS url
#
#  Expects the following structure as JSON via stdin:
#   {
#    "subscription_id": "<subscription id>",
#    "tenant_id": "<tenant id>",
#    "resource_group": "<resource group name>",
#    "storage_account": "<storage account name>",
#    "container": "<container name>",
#    "permissions": "<permissions string, see azure docs>",
#    "start_date": "<start date in ISO8601 format>",
#    "end_date": "<start date in ISO8601 format>"
#  }
#
#  And produces the following structure as JSON via stdout:
#  {
#    "url": "<SAS url>",
#    "token": "<SAS token only>"
#  }
#

# need to do this in python:

# az storage container generate-sas --name web-logs --account-name nomsstudiowebops --permissions rwdl --start 2017-05-15T00:00:00Z --expiry 2217-05-15T00:00:00Z


import json
import subprocess
import sys
import os.path
import shutil

from pprint import pprint

inputQuery = json.load(sys.stdin)

result = {"url": "", "token": ""}

sasToken = subprocess.run(
    ["az", "storage", "container", "generate-sas",
     "--name", inputQuery['container'],
     "--account-name", inputQuery['storage_account'],
     "--permissions", inputQuery['permissions'],
     "--start", inputQuery['start_date'],
     "--expiry", inputQuery['end_date'],
     "-o", "tsv"
     ],
    stdout=subprocess.PIPE,
    check=True
).stdout.decode().rstrip()

subprocess.run(
    ["az", "account", "get-access-token"],
    check=True, stdout=subprocess.DEVNULL
)


result["url"] = ''.join(
    ['https://', inputQuery['storage_account'], '.blob.core.windows.net/',
     inputQuery['container'], '?', sasToken])
result["token"] = sasToken

print(json.dumps(result))
