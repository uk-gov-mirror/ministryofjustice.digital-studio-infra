#!/usr/bin/env python3
import subprocess
import sys
import os.path

# get the root path for the repository

gitRoot = subprocess.run(
    ["git", "rev-parse", "--show-toplevel"],
    stdout=subprocess.PIPE,
    check=True
).stdout.decode().rstrip()

# Install Python requirements


def installDependencies():
    requirements = ''.join([gitRoot, "/tools/requirements.txt"])

    if subprocess.run(
        ["pip3", "install", "-r", requirements],
        check=True
    ):
        print("Dependency check completed")
        return True
    else:
        print("The dependency check could not be completed")
        return False

# Setup the symlink to init.py


def createLinks():

    scriptPath = ''.join([gitRoot, "/tools/init.py"])

    subprocess.run(
        ["chmod", "+x", scriptPath],
        check=True
    )

    symlink = '/usr/local/bin/diginit'

    # Activate relevant subscription in CLI
    if not os.path.islink(symlink):
        if subprocess.run(
            ["sudo", "ln", "-s", scriptPath, "/usr/local/bin/diginit"],
            check=True
        ):
            print("Symlink created")
            return True
        else:
            print("Symlink could not be created")
            return False
    else:
        print("Symlink already exists")
        return True


if installDependencies() and createLinks():
    print("Setup complete")
