#!/usr/bin/env python3

# Terraform external data source for reading data from an azure key vault
#
# Expects the following structure as JSON via stdin:
# {
#    "vault": "<name of vault>",
#    "<secret output name 1>": "<secret vault name 1>",
#    "<secret output name 2>": "<secret vault name 2>",
#    ...
#  }
#
#  And produces the following structure as JSON via stdout:
#  {
#   "<secret output name 1>": "<secret value 1>",
#   "<secret output name 2>": "<secret value 2>",
#    ...
#  }

import json
import subprocess
import sys
import logging

# from functions import get_users

sys.path.insert(0, '../../')

from tools.python_modules import azure_account

if sys.stdin:
    args = json.load(sys.stdin)

    vault_name = args['vault']

    input_items = args

    del input_items['vault']

users = azure_account.get_secrets(input_items, vault_name)

print(json.dumps(users))
