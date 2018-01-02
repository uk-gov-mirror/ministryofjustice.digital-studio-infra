#!/usr/bin/env python3
import json, subprocess
import sys
import os.path

gitRoot = subprocess.run(
    ["git", "rev-parse", "--show-toplevel"],
    stdout=subprocess.PIPE, encoding='utf8',
    check=True
).stdout

scriptPath = ''.join([gitRoot.rstrip(),"/tools/init.py"])


subprocess.run(
    ["chmod", "+x", scriptPath],
    check=True
)

# Activate relevant subscription in CLI
if not os.symlink(scriptPath,'/usr/bin/diginit'):
    subprocess.run(
    ["sudo", "ln", "-s", scriptPath, "/usr/bin/diginit"],
    check=True
    )
