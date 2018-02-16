#!/usr/bin/env python3
import subprocess
import sys
import os.path
import argparse
import logging
import pathlib
import shutil

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

parser = argparse.ArgumentParser(
    description='Script to create a basic app directory')

parser.add_argument("-a", "--app-name", help="App name")
parser.add_argument("-e", "--environments", help="Environments: comma separated list of dev,stage,mock,testing,preprod,prod")

args = parser.parse_args()

def create_app_boilerplate(app_directory,environments):

    for environment in environments:
        app_dev_directory = app_directory + "/" + environment
        app_name =  app_directory + "-" + environment

        pathlib.Path(app_dev_directory).mkdir(parents=True)

        src = "tools/config/main.tf"

        main_terraform = app_dev_directory + "/main.tf"

        s = open(src).read()
        s = s.replace('APPNAME', app_name)
        f = open(main_terraform, 'w')
        f.write(s)
        f.close()

if not os.path.isdir(args.app_name):

    environments = args.environments.split(",")

    create_app_boilerplate(args.app_name,environments)

else:
    logging.warn("App directory already exists")
    sys.exit("Exit")
