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
parser.add_argument("-v", "--vault", help="KeyVault to store certificate in")

args = parser.parse_args()

domain = args.hostname + '.' + args.zone


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


def create_certificate(hostname, zone, domain, resource_group, certbot_location):

    # Ensure the hook scripts are executable and that teh log file is writable
    subprocess.run(
        ["sudo", "chmod", "-R", "770", "letsencrypt"],
        check=True
    )

    certbot = certbot_location + "certbot"

    host_challenge_name = '_acme-challenge.' + hostname

    manual_auth_hook = "letsencrypt/authenticator.py {host} {zone} {resource_group}".format(
        host=host_challenge_name, zone=zone, resource_group=resource_group)

    manual_cleanup_hook = "letsencrypt/cleanup.py {host} {zone} {resource_group}".format(
        host=host_challenge_name, zone=zone, resource_group=resource_group)

    cert_details = subprocess.run(
        ["sudo", certbot, "certonly", "--manual",
         "--email", "noms-studio-webops@digital.justice.gov.uk",
         "--preferred-challenges", "dns",
         "-d", domain,
         "--manual-auth-hook", manual_auth_hook,
         "--manual-cleanup-hook", manual_cleanup_hook,
         "--manual-public-ip-logging-ok",
         "--duplicate"
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    return cert_details


def create_pkcs12(domain):

    path_to_cert = "/etc/letsencrypt/live/" + domain + "/fullchain.pem"
    path_to_key = "/etc/letsencrypt/live/" + domain + "/privkey.pem"
    export_path = "letsencrypt/certificates/" + domain + ".p12"

    subprocess.run(
        ["sudo", "openssl", "pkcs12", "-export",
         "-inkey", path_to_key,
         "-in", path_to_cert,
         "-out", export_path,
         "-passout", "pass:"
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    return export_path


def store_certificate(cert_file, vault, domain):

    name = domain.replace(".", "DOT")

    subprocess.run(
        ["az", "keyvault", "certificate", "import",
         "--file", cert_file,
         "--name", name,
         "--vault-name", "notm-dev"
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()


azure_account.azure_set_subscription(args.subscription_id)

if not get_zone_details(args.resource_group, args.zone):
    sys.exit("Failed to find existing zone " + args.zone)

create_certificate(
    args.hostname, args.zone, domain, args.resource_group, args.certbot)

cert_file = create_pkcs12(domain)

store_certificate(cert_file, args.vault, domain)
