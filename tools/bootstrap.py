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

args = parser.parse_args()

def create_app_boilerplate(app_directory):

    app_dev_directory = app_directory + "/dev"

    pathlib.Path(app_dev_directory).mkdir(parents=True)

    src = "tools/config/main.tf"

    main_terraform = app_dev_directory + "/main.tf"

    s = open(src).read()
    s = s.replace('APPDIRECTORY', app_directory)
    f = open(main_terraform, 'w')
    f.write(s)
    f.close()

if not os.path.isdir(args.app_name):
    create_app_boilerplate(args.app_name)

else:
    logging.warn("App directory already exists")
    sys.exit("Exit")
