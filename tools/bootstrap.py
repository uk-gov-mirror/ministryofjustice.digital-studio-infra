#!/usr/bin/env python3
import subprocess
import sys
import os.path
import argparse
import logging
import pathlib
import shutil

from python_modules import azure_account

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

parser = argparse.ArgumentParser(
    description='Script to create a basic app directory')

parser.add_argument("-a", "--app-name", help="App name")
parser.add_argument("-e", "--environments", help="Environments: comma separated list of dev,stage,mock,preprod,prod")

args = parser.parse_args()

def create_app_boilerplate(app_name,environments):

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
        f = open(main_terraform, 'w')
        f.write(s)
        f.close()

if not os.path.isdir(args.app_name):

    environments = args.environments.split(",")

    create_app_boilerplate(args.app_name,environments)

else:
    logging.warn("App directory already exists")
    sys.exit("Exit")
