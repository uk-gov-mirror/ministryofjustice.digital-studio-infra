#!/usr/bin/env python3

# Manage the list of users used to created AWS accounts. For most actions a complete list of users is required.

import json
import subprocess
import sys
import os.path
import logging
import argparse

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

parser = argparse.ArgumentParser(
    description='Script to create the config for AWS user accounts')

parser.add_argument("-e", "--environment", help="Prod or Devtest environment")
parser.add_argument("-u", "--users", help="Users to add/del to AWS")
parser.add_argument("-a", "--user-action", help="Add or delete Users (add/del)")
parser.add_argument("-g", "--group", help="user type to update e.g. webops, developers etc.")

args = parser.parse_args()

def manage_users(environment, user_action,group):

    user_types = ['webops','developers']

    usersTfJson = {
      "variable": {
      "aws_users_webops":{"default" : []},
      "aws_users_developers":{"default" : []},
      }
    }

    vault_name = "aws-users-" + environment

    logging.info("Creating users.tf.json")

    for user_type in user_types:
        logging.info("Checking " + user_type )

        user_list = []

        try:
            user_list = subprocess.run(
                ["az", "keyvault", "secret", "show",
                 "--vault-name", vault_name,
                 "--name", "users-" + user_type
                 ],
                stdout=subprocess.PIPE,
                check=True
            ).stdout.decode()

            user_list = json.loads(user_list)

            user_list = user_list["value"].split(",")
            print(user_list)
            user_list = list(filter(None, user_list))
            print(user_list)

        except subprocess.CalledProcessError:
            logging.info("Key vault secret for " + user_type + " doesn't exist. It will be created if required.")

        users = args.users.split(",")

        for user in users:
            if user_action == "add" and user_type == group :
                if user not in user_list:
                    user_list.append(user)
                    logging.info("User " + user + " created" )
                else:
                    logging.warn("User " + user + " already exists" )
            elif user_action == "del" and user_type == group:
                if user in user_list:
                    user_list.remove(user)
                    logging.info("User " + user + " deleted" )
                else:
                    logging.warn("User " + user + " does not exist" )

        user_type_key = "aws_users_" + user_type

        usersTfJson["variable"][user_type_key]["default"] = user_list

        if not user_list:

            store_user_list = ","
        else:
            store_user_list = ",".join(user_list)

        user_list_update_cmd = ["az", "keyvault", "secret", "set",
        "--vault-name", vault_name,
         "--name", "users-" + user_type,
         "--value", store_user_list]

        try:
            user_list = subprocess.run(
               user_list_update_cmd,
               stdout=subprocess.PIPE,
               check=True
            ).stdout.decode()
        except subprocess.CalledProcessError:
            sys.exit("There was an error storing the user list to the vault")

manage_users(args.environment, args.user_action, args.group)
