# Activate the relevant subscription in CLI
import subprocess


def azure_set_subscription(subscription_id):

    subprocess.run(
        ["az", "account", "set", "--subscription", subscription_id],
        check=True
    )


def azure_access_token(subscription_id=None):

    subscription_params = []

    if subscription_id:
        subscription_params = ["--subscription", subscription_id]

    subprocess.run(
        ["az", "account", "get-access-token", *subscription_params],
        check=True, stdout=subprocess.DEVNULL
    )
