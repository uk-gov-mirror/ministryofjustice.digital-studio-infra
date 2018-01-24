#!/usr/bin/env python3

# Create a Letsencrypt certificate(https: // letsencrypt.org) and store it in an azure key vault.

import json
import subprocess
import os
import sys
import argparse
import base64
import re

from time import gmtime, strftime, strptime
from datetime import datetime

from python_modules import azure_account

parser = argparse.ArgumentParser(
    description='Script to create Letsencrypt SSL certificates and store in Azure Key Vault')

parser.add_argument("-z", "--zone", help="DNS Zone")
parser.add_argument("-n", "--hostname", help="Hostname")
parser.add_argument("-g", "--resource-group", help="Resource Group")
parser.add_argument("-s", "--subscription-id", help="Subscription ID")
parser.add_argument("-c", "--certbot",
                    help="Certbot installation directory e.g. /usr/usr/local/opt/letsencrypt/bin/certbot")
parser.add_argument("-v", "--vault", help="KeyVault to store certificate in")

args = parser.parse_args()

fqdn = args.hostname + '.' + args.zone


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


def create_certificate(hostname, zone, fqdn, resource_group, certbot_location):

    host_challenge_name = '_acme-challenge.' + hostname

    manual_auth_hook = "python3 letsencrypt/authenticator.py {host} {zone} {resource_group}".format(
        host=host_challenge_name, zone=zone, resource_group=resource_group)

    manual_cleanup_hook = "python3 letsencrypt/cleanup.py {host} {zone} {resource_group}".format(
        host=host_challenge_name, zone=zone, resource_group=resource_group)

    try:
        certificate = subprocess.run(
            [certbot_location, "certonly", "--manual",
             "--email", "noms-studio-webops@digital.justice.gov.uk",
             "--preferred-challenges", "dns",
             "-d", fqdn,
             "--manual-auth-hook", manual_auth_hook,
             "--manual-cleanup-hook", manual_cleanup_hook,
             "--manual-public-ip-logging-ok",
             "--force-renewal"
             "--config-dir", certbot_location,
             "--work-dir", certbot_location,
             "--logs-dir", certbot_location
             ],
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()
    except subprocess.CalledProcessError:
        sys.exit("There was an error creating the certificate")

    path_to_cert = "/etc/letsencrypt/live/" + fqdn + "/fullchain.pem"

    if os.path.exists(path_to_cert):
        return True
    else:
        return False


def create_pkcs12(fqdn):

    path_to_cert = "/etc/letsencrypt/live/" + fqdn + "/fullchain.pem"
    path_to_key = "/etc/letsencrypt/live/" + fqdn + "/privkey.pem"
    export_path = "letsencrypt/certificates/" + fqdn + ".p12"

    subprocess.run(
        ["openssl", "pkcs12", "-export",
         "-inkey", path_to_key,
         "-in", path_to_cert,
         "-out", export_path,
         "-passout", "pass:"
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    if os.path.exists(export_path):
        return export_path
    else:
        return False


def store_certificate(vault, fqdn):

    name = fqdn.replace(".", "DOT")

    cert_file = create_pkcs12(fqdn)

    cert_dates = get_certificate_expiry(fqdn)

    open_pkcs12 = open(cert_file, 'rb').read()
    cert_encoded = base64.encodestring(open_pkcs12)

    subprocess.run(
        ["az", "keyvault", "secret", "set",
         "--file", cert_file,
         "--encoding", "base64",
         "--name", name,
         "--vault-name", vault
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    subprocess.run(
        ["az", "keyvault", "secret", "set-attributes",
         "--name", name,
         "--content-type", "application/x-pkcs12",
         "--expires", cert_dates["end"],
         "--not-before", cert_dates["start"],
         "--vault-name", "notm-dev"
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()


def get_certificate_expiry(fqdn):

    cert_dates = {}

    cert_expiry_data = subprocess.run(
        ["openssl", "x509",
         "-startdate",
         "-enddate",
         "-noout",
         "-in", "/etc/letsencrypt/live/" + fqdn + "/fullchain.pem",
         "-inform", "pem"
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    cert_expiry = cert_expiry_data.splitlines(True)

    for certdate in cert_expiry:

        if certdate.find("notBefore") != -1:
            start_end = "start"

        elif certdate.find("notAfter") != -1:
            start_end = "end"
        else:
            sys.exit("The certificate appears to have missing dates")

        certdate = certdate.rstrip()
        certdate = re.sub(r"not(After|Before)=", '', certdate)

        expiry_date_from_string = strptime(
            certdate, "%b %d %H:%M:%S %Y %Z")

        formatted_expiry_date = strftime(
            "%Y-%m-%dT%H:%M:%SZ", expiry_date_from_string)

        cert_dates[start_end] = formatted_expiry_date

    return cert_dates


azure_account.azure_set_subscription(args.subscription_id)

if not get_zone_details(args.resource_group, args.zone):
    sys.exit("Failed to find existing zone " + args.zone)

if create_certificate(args.hostname, args.zone, fqdn,
                      args.resource_group, args.certbot):

    store_certificate(args.vault, fqdn)
else:
    sys.exit("There was a problem creating the certificate")
