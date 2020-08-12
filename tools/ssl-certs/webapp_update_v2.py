#!/usr/bin/env python3
import subprocess
import sys
import os.path
import argparse
import logging

parser = argparse.ArgumentParser(
    description='Script to update an SSL certificate on an Azure Application Gateway')

parser.add_argument('-g', '--webapp-resource-group', help='Azure WebApp resource_group')
parser.add_argument('-b', '--webapp-subscription-id', help='Azure WebApp subscription id')
parser.add_argument('-a', '--webapp-name', help='Azure WebApp name')
parser.add_argument('-k', '--key-vault', help='Azure Key Vault where the certificate is stored')
parser.add_argument('-s', '--key-vault-subscription-id', help='Azure KeyVault subscription id')
parser.add_argument('-c', '--key-vault-cert-name', help='Name of the certificate in KeyVault')
parser.add_argument('-debug', '--debug', help='Change logging level to debug.', action='store_true')

args = parser.parse_args()

if args.debug:
    print('Setting logging level to debug')
    logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)
    logging.getLogger().setLevel(10)
else:
    print('Setting logging level to info')
    logging.basicConfig(stream=sys.stdout, level=logging.INFO)
    logging.getLogger().setLevel(20)


def update_ssl_cert(webapp_name, webapp_resource_group, webapp_subscription, kv_name, kv_certname):

    logging.info('function: update_ssl_cert.')

    try:
        subprocess.run(
            ['az', 'account', 'set',
             '-s', webapp_subscription
             ],
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()

    except subprocess.CalledProcessError:
        sys.exit('There was an error setting the subscription')

    logging.info('Importing cert to Azure Webapp.')

    cmd = ['az', 'webapp', 'config', 'ssl', 'import',
           '--name', webapp_name,
           '--resource-group', webapp_resource_group,
           '--key-vault', kv_name,
           '--key-vault-certificate-name', kv_certname
           ]
    logging.info('Running: %s' % (' '.join(cmd)))

    try:
        set_secret = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            check=True
        )
        logging.info(set_secret)

    except subprocess.CalledProcessError:
        sys.exit('There was an error updating the webapp SSL certificate.')

    logging.info('Completed')


if not args.webapp_name:
    sys.exit('Missing arguments, use --help for usage')

if args.webapp_subscription_id != args.key_vault_subscription_id:
    sys.exit('Webapp and Keyvault must be in the same subscription')

update_ssl_cert(args.webapp_name, args.webapp_resource_group, args.webapp_subscription_id, args.key_vault, args.key_vault_cert_name)
