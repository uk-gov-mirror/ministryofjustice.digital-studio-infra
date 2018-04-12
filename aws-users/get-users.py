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

from functions import get_users

if sys.stdin:
    args = json.load(sys.stdin)

    vault_name = args['vault']

    input_items = args

    del input_items['vault']

users = get_users(input_items, vault_name)

jsonFile = json.dumps(users, indent=2)

users_file = "users.json"

with open(users_file, "w") as f:
    f.write(jsonFile)

print(json.dumps(users))
