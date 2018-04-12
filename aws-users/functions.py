#!/usr/bin/env python3

import json
import subprocess
import sys
import logging

def get_users(inputItems,vault_name):

    secrets = {}

    for key, value in inputItems.items():
        try:
            secret = subprocess.run(
                ["az", "keyvault", "secret", "show", "--vault-name",
                 vault_name, "--name", value
                 ],
                stdout=subprocess.PIPE,
                check=True
            ).stdout.decode()

            data = json.loads(secret)

            secrets[key] = data["value"]
        except subprocess.CalledProcessError:
            logging.warn("Couldn't retrieve secret")
            secrets[key] = ""

    return secrets
