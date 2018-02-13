#!/usr/bin/env python3
import json
import subprocess
import sys
import os.path
import shutil


def create_storage_account(resource_group, storage_account):

    resource_group_exists = subprocess.run(
        ["az", "group", "show",
        "--name", resource_group ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    if not resource_group_exists:
      subprocess.run(
          ["az", "group", "create",
          "--location", "ukwest",
          "--name", resource_group,
          ],
          stdout=subprocess.PIPE,
          check=True
      ).stdout.decode()


    accounts = json.loads(subprocess.run(
        ["az", "storage", "account", "list"],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode())

    account_names = []

    for name in accounts:
      account_names.append(name['name'])

    if storage_account not in account_names:
      subprocess.run(
          ["az", "storage", "account", "create",
          "--name", storage_account,
          "--resource-group", resource_group,
          ],
          stdout=subprocess.PIPE,
          check=True
      ).stdout.decode()

    response = json.loads(subprocess.run(
        ["az", "storage", "container", "exists",
         "--account-name", storage_account,
         "--name", "terraform",
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode())

    if response["exists"] == False:
        subprocess.run(
            ["az", "storage", "container", "create",
             "--account-name", storage_account,
             "--name", "terraform"
             ],
            stdout=subprocess.PIPE,
            check=True
        )
