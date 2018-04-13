#!/usr/bin/env python3

# Decrypts the first time passwords set up for users.

import json
import subprocess
import sys
import os.path
import logging
import base64
import argparse

sys.path.insert(0, '../../')

from tools.python_modules import azure_account

parser = argparse.ArgumentParser(
    description='Script to decrypt first time user passwords')

parser.add_argument("-e", "--environment", help="Prod or Devtest environment")

args = parser.parse_args()

input_items = {
  "users-webops":"users-webops",
  "users-developers":"users-developers"
  }

vault_name = "aws-users-" + args.environment

aws_user_accounts = azure_account.get_secrets(input_items, vault_name)

user_list = []

for aws_user_type in aws_user_accounts:

    users = aws_user_accounts[aws_user_type].split(",")

    for user in users:
        if user != '':
            user_list.append(user)

try:
   terraform_output = subprocess.run(
        ["terraform", "state", "pull"],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()
except:
    logging.info("Could not get Terraform output")

terraform_output_json = json.loads(terraform_output)

def get_passwords(number_of_users):

    for i in range(number_of_users):

        user_profile = terraform_output_json['modules'][0]['resources']["aws_iam_user_login_profile.user." + str(i)]

        user = user_profile['primary']['id']

        password = user_profile['primary']['attributes']['encrypted_password']

        decoded_passsword = base64.b64decode(password)

        try:
           user_password = subprocess.run(
               ["gpg", "-d", "-q"],
               stdout=subprocess.PIPE,
               input=decoded_passsword,
               check=True
           ).stdout.decode()
        except:
          logging.info("Could not decrypt the password")
          return False

        print(user + ": " + user_password)

get_passwords(len(user_list))
