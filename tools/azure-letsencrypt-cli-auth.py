#!/usr/bin/env python3

# Create a Letsencrypt certificate(https: // letsencrypt.org) and store it in an azure key vault.

import json
import subprocess
import os
import sys
import argparse

from python_modules import azure_account

parser = argparse.ArgumentParser()

#-db DATABSE -u USERNAME -p PASSWORD -size 20
parser.add_argument("-z", "--zone", help="DNS Zone")
parser.add_argument("-n", "--hostname", help="Hostname")
parser.add_argument("-g", "--resource-group", help="Resource Group")
parser.add_argument("-s", "--subscription-id", help="Subscription ID")
parser.add_argument("-c", "--certbot",
                    help="Certbot installation directory")

args = parser.parse_args()


def get_zone_details(resource_group, zone):

    find_dns_records = subprocess.run(
        ["az", "network", "dns", "record-set", "soa", "show",
         "-g", resource_group, "-z", zone
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    if find_dns_records:
        dns_records = json.loads(find_dns_records)

        key = "fqdn"

        for key, zone in dns_records.items():
            return True
        else:
            return False
    else:
        return False


def create_certificate(hostname, zone, certbot_location):

    # key authorisation
    # Create TXT record
    # Create cert
    # Delete TXT record
    scriptPath = 'authenticator.sh'

    subprocess.run(
        ["chmod", "+x", scriptPath],
        check=True
    )

    certbot = certbot_location + "certbot"

    # Set the enivronment variables
    #os.environ["CERTBOT_DOMAIN"] = '_acme-challenge.' + hostname
    #os.putenv["CERTBOT_VALIDATION"] = 'blahblahblah'

    subprocess.run(
        ["sudo", certbot, "certonly", "--manual",
         "--email", "noms-studio-webops@digital.justice.gov.uk",
         "--preferred-challenges", "dns",
         "-d", hostname + '.' + zone,
         "--manual-auth-hook", "./authenticator.sh",
         "--agree-tos"
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    # then tidy up and delete the env variables


azure_account.azure_set_subscription(args.subscription_id)

if not get_zone_details(args.resource_group, args.zone):
    sys.exit("Failed to find existing zone " + args.zone)

create_certificate(args.hostname, args.zone, args.certbot)
