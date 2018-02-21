#!/usr/bin/env python3
import subprocess
import sys
import os.path
import argparse
import logging
import pathlib
import shutil
import json

from python_modules import azure_account

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

parser = argparse.ArgumentParser(
    description='Script to create a basic app directory')

parser.add_argument("-a", "--app-name", help="App name")
parser.add_argument("-e", "--environments", help="Environments: comma separated list of dev,stage,mock,preprod,prod")

args = parser.parse_args()

def create_app_boilerplate(app_name,environments,oid):

    logging.info("Creating local directory structure")

    for environment in environments:
        app_dev_directory = app_name + "/" + environment

        storage_account = app_name.replace('-','') + environment + "storage"

        pathlib.Path(app_dev_directory).mkdir(parents=True)

        prod_envs = ['prepod','prod']

        if environment in prod_envs:
            os.symlink(azure_account.get_git_root() + "/azure-prod.tf",app_dev_directory + '/azure-prod.tf')
        else:
            os.symlink(azure_account.get_git_root() + "/azure-devtest.tf",app_dev_directory + '/azure-devtest.tf')


        src = "tools/config/main.tf"

        main_terraform = app_dev_directory + "/main.tf"

        s = open(src).read()
        s = s.replace('APPNAME', app_name)
        s = s.replace('ENVIRONMENT', environment)
        s = s.replace('STORAGE', storage_account)
        s = s.replace('AD_GROUP_OID', oid)
        f = open(main_terraform, 'w')
        f.write(s)
        f.close()

def create_ad_group(app_name):

    display_name = "Digital Studio Dev Team - " + app_name

    check_account_group_json = {"displayName":""}

    try:
        check_account_group = subprocess.run(
            ["az", "ad", "group", "show",
                "--group", display_name
             ],
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()

        check_account_group_json = json.loads(check_account_group)

    except:
        logging.info("Azure AD Group does not exist")

    if check_account_group_json["displayName"] != display_name:

        logging.info("Creating Azure AD Group")
        account_group = subprocess.run(
            ["az", "ad", "group", "create",
                "--display-name", display_name,
                "--mail-nickname", "null"
             ],
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()

        account_group_oid = json.loads(account_group)

        return account_group_oid["objectId"]
    else:
        logging.info("Group exists")
        return check_account_group_json["objectId"]


if not os.path.isdir(args.app_name):

    oid = create_ad_group(args.app_name)

    environments = args.environments.split(",")

    create_app_boilerplate(args.app_name,environments,oid)

else:
    logging.warn("App directory already exists")
    sys.exit("Exit")
