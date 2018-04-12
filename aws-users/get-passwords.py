#!/usr/bin/env python3

# Decrypts the first time passwords set up for users.

import json
import subprocess
import sys
import os.path
import logging
import base64
import argparse

from functions import get_users

parser = argparse.ArgumentParser(
    description='Script to decrypt first time user passwords')

parser.add_argument("-e", "--environment", help="Prod or Devtest environment")

args = parser.parse_args()

input_items = {
  "aws_users_webops":"users-webops",
  "aws_users_developers":"users-developers"
  }

vault_name = "aws-users-" + args.environment

aws_user_accounts = get_users(input_items, vault_name)


def get_passwords():

    try:
       terraform_output = subprocess.run(
            ["terraform", "output", "-json", "password"],
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()
    except:
        logging.info("Could not get Terraform output")
        return False

    terraform_output_json = json.loads(terraform_output)

    for aws_user_type in aws_user_accounts:

        users = aws_user_accounts[aws_user_type].split(",")

        for user in users:

            if user in terraform_output_json["value"]:

                try:

                   decoded_passsword = base64.b64decode(terraform_output_json["value"][user])

                   user_password = subprocess.run(
                       ["gpg", "-d"],
                       stdout=subprocess.PIPE,
                       input=decoded_passsword,
                       check=True
                   ).stdout.decode()
                except:
                  logging.info("Could not decrypt the password")
                  return False

                print(user + ": " + user_password)

get_passwords()
