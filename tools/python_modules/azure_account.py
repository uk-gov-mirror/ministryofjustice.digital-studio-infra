# Activate the relevant subscription in CLI
import subprocess


def azure_user_access(subscription_id):

    subprocess.run(
        ["az", "account", "set", "--subscription", subscription_id],
        check=True
    )
