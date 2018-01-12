# Create a backup of the state
import subprocess
import os.path
from time import gmtime, strftime
import glob
import fnmatch


def backup():

    date_stamp = strftime("%Y-%m-%dT%H:%M:%S", gmtime())

    backup_file = ".terraform/tfstate." + date_stamp + ".backup"

    current_state = subprocess.run(
        ["terraform", "state",  "pull"],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    with open(backup_file, "w") as f:
        f.write(current_state)

    # Retain the 5 most recent backups
    while len(fnmatch.filter(os.listdir('.terraform'), 'tfstate.*.backup')) > 5:
        oldest = min(
            glob.iglob('.terraform/tfstate.*.backup'), key=os.path.getctime)

        os.remove(oldest)
