#!/usr/bin/env python3
import subprocess
import sys
import os.path
import argparse
import logging
import json

sys.path.insert(0, './')

parser = argparse.ArgumentParser(
    description='Script to add or update a backend certificate on an Azure Application Gateway')

parser.add_argument('-g', '--resource-group', help='App gateway resource_group')
parser.add_argument('-b', '--gw-subscription-id', help='App gateway subscription id')
parser.add_argument('-n', '--gw-cert-name', help='App gateway backend cert name (if not provided use thumbprint as name)')
parser.add_argument('-l', '--gw-http-settings-name', help='App gateway http settings name (if present, also add cert to http settings)')
parser.add_argument('-a', '--gateway-name', help='App Gateway name')
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

    if gw_cert_name is None:
        try:
            x509_cert_file = cert_file + '.x509'

            x509 = subprocess.run(
                ['openssl', 'pkcs12', '-nokeys',
                 '-in', cert_file,
                 '-out', x509_cert_file,
                 '-password', 'pass:'],
                stdout=subprocess.PIPE,
                check=True
            ).stdout.decode()

            fingerprint = subprocess.run(
                ['openssl', 'x509', '-fingerprint', '-noout',
                 '-in', x509_cert_file],
                stdout=subprocess.PIPE,
                check=True
            ).stdout.decode().rstrip()

            gw_cert_name = ''.join(fingerprint.split('=', 1)[1].split(':'))

            logging.info("gw-cert-name not specified, using fingerprint as name: %s", gw_cert_name)

        except subprocess.CalledProcessError:
            sys.exit('There was an error reading parsing backend cert')

    cmd = ['az', 'network', 'application-gateway', 'auth-cert', 'show',
           '--gateway-name', app_gateway_name,
           '--resource-group', resource_group,
           '--name', gw_cert_name,
           '--query', 'provisioningState',
           '-o', 'tsv']
    logging.info('Running: %s' % (' '.join(cmd)))

    authCertShowResult = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False
    )
    logging.info("Auth-cert show provisioningState output: %s", authCertShowResult.stdout.decode().rstrip())

    if authCertShowResult.returncode == 0:
        logging.info("Auth certificate already exists, updating...")

        cmd = ['az', 'network', 'application-gateway', 'auth-cert', 'update',
               '--gateway-name', app_gateway_name,
               '--resource-group', resource_group,
               '--name', gw_cert_name,
               '--cert-file', cert_file
               ]
    else:
        logging.info("Auth certificate doesn't exist, creating...")

        cmd = ['az', 'network', 'application-gateway', 'auth-cert', 'create',
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

    return gw_cert_name


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
        if os.path.isfile(savecert):
            logging.info('Removing previous cert: %s', savecert)
            os.remove(savecert)

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
    except OSError as error:
        sys.exit('There was an error removing previous file')


def add_cert_to_http_settings(app_gateway_name, resource_group, http_settings_name,  gw_cert_name, gw_subscription):

    logging.info('function: add_cert_to_http_settings.')

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

    try:
        cmd = ['az', 'network', 'application-gateway', 'http-settings', 'show',
               '--gateway-name', app_gateway_name,
               '--resource-group', resource_group,
               '--name', http_settings_name,
               '--query', 'authenticationCertificates[].id']
        logging.info('Running: %s' % (' '.join(cmd)))

        authCertIdOutput = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode().rstrip()

    except subprocess.CalledProcessError:
        sys.exit('There was an error retrieving the http settings from the application gateway')

    try:
        logging.debug("Http-settings output: %s", authCertIdOutput)
        authCertIds = json.loads(authCertIdOutput)
        authCertNames = [authCertId.split('/')[-1] for authCertId in authCertIds]
    except json.JSONDecodeError:
        logging.info("Cannot parse http settings output: %s", authCertIdOutput)
        sys.exit('There was an error parsing the http settings JSON')

    if gw_cert_name in authCertNames:
        print("Certificate already present in the application gateway http settings auth list")
        return

    print("Adding certificate to application gateway http settings auth list")
    authCertNames.append(gw_cert_name)

    try:
        cmd = ['az', 'network', 'application-gateway', 'http-settings', 'update',
               '--auth-certs', ' '.join(authCertNames),
               '--gateway-name', app_gateway_name,
               '--resource-group', resource_group,
               '--name', http_settings_name,
               '--query', 'authenticationCertificates[].id']
        logging.info('Running: %s' % (' '.join(cmd)))

        authCertUpdate = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()

        logging.debug("Result: %s", authCertUpdate)

    except subprocess.CalledProcessError:
        sys.exit('There was an error updating the application gateway http settings')

    logging.info('Cert successfully added to application gateway http settings')

cert_file = args.key_vault_cert_name + '.cer'

certificate = get_cert_from_keyvault(args.key_vault, args.key_vault_cert_name, args.key_vault_subscription_id)

cert_name = update_auth_cert(args.gateway_name, args.resource_group, args.gw_cert_name, args.key_vault, cert_file, args.gw_subscription_id)

if not args.gw_http_settings_name is None:
    add_cert_to_http_settings(args.gateway_name, args.resource_group, args.gw_http_settings_name, cert_name, args.gw_subscription_id)
