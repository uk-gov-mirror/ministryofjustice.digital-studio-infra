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
from python_modules import azure_account


def generate_sas(input_query):

    result = {"url": "", "token": ""}

    sas_token = subprocess.run(
        ["az", "storage", "container", "generate-sas",
         "--name", input_query['container'],
         "--account-name", input_query['storage_account'],
         "--permissions", input_query['permissions'],
         "--start", input_query['start_date'],
         "--expiry", input_query['end_date'],
         "-o", "tsv"
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode().rstrip()

    result["url"] = ''.join(
        ['https://', input_query['storage_account'], '.blob.core.windows.net/',
         input_query['container'], '?', sas_token])
    result["token"] = sas_token

    return(json.dumps(result))


input_query = json.load(sys.stdin)

azure_account.azure_user_access(input_query['subscription_id'])

print(generate_sas(input_query))
