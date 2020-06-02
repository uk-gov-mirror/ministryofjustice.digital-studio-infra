#!/usr/bin/env python3
import subprocess
import sys
import os.path
import argparse
import logging

sys.path.insert(0, './')

parser = argparse.ArgumentParser(
    description='Script to update an backend certificate on an Azure Application Gateway')

parser.add_argument('-g', '--resource-group', help='resource_group')
parser.add_argument('-b', '--gw-subscription-id', help='App gateway subscription id')
parser.add_argument('-n', '--gw-cert-name', help='Azure app gw listener cert name')
parser.add_argument('-a', '--gateway-name', help='Azure Application Gateway name')
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


def update_auth_cert(app_gateway_name, resource_group, gw_cert_name, key_vault, cert_file, gw_subscription):

    logging.info('function: update_auth_cert.')
    logging.debug("Value of 'cert_file' is: %s", cert_file)

    try:
        subprocess.run(
            ['az', 'account', 'set',
             '-s', gw_subscription
             ],
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()

    except subprocess.CalledProcessError:
        sys.exit('There was an error setting the subscription')

    logging.info('Updating Application Gateway with new certificate.')

    if args.debug:
        try:
            app_gw_info = subprocess.run(
                ['az', 'network', 'application-gateway', 'auth-cert', 'list',
                 '--gateway-name', app_gateway_name,
                 '--resource-group', resource_group
                 ],
                stdout=subprocess.PIPE,
                check=True
            ).stdout.decode()

        except subprocess.CalledProcessError:
            sys.exit('There was an error reading app gw config')

        logging.debug("Initial value of 'app_gw_info' is: %s", app_gw_info)

    cmd = ['az', 'network', 'application-gateway', 'auth-cert', 'update',
           '--gateway-name', app_gateway_name,
           '--resource-group', resource_group,
           '--name', gw_cert_name,
           '--cert-file', cert_file
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
        sys.exit('There was an error updating the application gateway backend certificate.')

    if args.debug:
        try:
            app_gw_info = subprocess.run(
                ['az', 'network', 'application-gateway', 'auth-cert', 'list',
                 '--gateway-name', app_gateway_name,
                 '--resource-group', resource_group
                 ],
                stdout=subprocess.PIPE,
                check=True
            ).stdout.decode()

        except subprocess.CalledProcessError:
            sys.exit('There was an error reading app gw config')

        logging.debug("Updated value of 'app_gw_info' is: %s", app_gw_info)


def get_cert_from_keyvault(vault_name, cert_name, vault_subscription):

    logging.debug('function: get_cert_from_keyvault')
    logging.debug('vault_subscription is: %s', vault_subscription)

    try:
        subprocess.run(
            ['az', 'account', 'set',
             '-s', vault_subscription
             ],
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()

    except subprocess.CalledProcessError:
        sys.exit('There was an error setting the subscription')

    savecert = cert_name + '.cer'

    try:
        vault = subprocess.run(
            ['az', 'keyvault', 'show',
             '--name', vault_name
             ],
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()

        if vault:
            logging.debug('vault exists!')
        else:
            sys.exit('Cannot access vault!')

    except subprocess.CalledProcessError:
        sys.exit('There was an error accessing the key vault')

    try:
        cmd = ['az', 'keyvault', 'secret', 'download',
               '--name', cert_name,
               '--vault-name', vault_name,
               '--file', savecert,
               '--encoding', 'base64'
               ]

        cert = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()

        return cert

    except subprocess.CalledProcessError:
        sys.exit('There was an error retrieving cert from the key vault')


cert_file = args.key_vault_cert_name + '.cer'

certificate = get_cert_from_keyvault(args.key_vault, args.key_vault_cert_name, args.key_vault_subscription_id)


update_auth_cert(args.gateway_name, args.resource_group, args.gw_cert_name, args.key_vault, cert_file, args.gw_subscription_id)
