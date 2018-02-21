# Activate the relevant subscription in CLI
import subprocess
import json
import logging
import sys
import string
import random

logging.basicConfig(stream=sys.stdout, level=logging.INFO)


def azure_set_subscription(subscription_id):

    subprocess.run(
        ["az", "account", "set", "--subscription", subscription_id],
        check=True
    )

def azure_access_token(subscription_id=None):

    subscription_params = []

    if subscription_id:
        subscription_params = ["--subscription", subscription_id]

    subprocess.run(
        ["az", "account", "get-access-token", *subscription_params],
        check=True, stdout=subprocess.DEVNULL
    )


def get_git_root():

    git_root = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode().rstrip()

    return git_root


def get_secrets(secrets, vault_name):

    secret_values = {}

    for key in secrets:

        try:
            secret = subprocess.run(
                ["az", "keyvault", "secret", "show", "--vault-name",
                 vault_name, "--name", key
                 ],
                stdout=subprocess.PIPE,
                check=True
            ).stdout.decode()

            data = json.loads(secret)

            secret_values[key] = data["value"]

        except subprocess.CalledProcessError:
            logging.warn("Can't read secret from key vault. Exiting.")
            sys.exit(1)


    return secret_values

def create_password():
    alphabet = string.ascii_letters + string.digits
    password = ''.join(random.choice(alphabet) for i in range(20))

    return password
