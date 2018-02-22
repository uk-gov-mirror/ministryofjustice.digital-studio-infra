#!/usr/bin/env python3
import json
import subprocess
import sys
import os.path
import argparse
import logging

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

parser = argparse.ArgumentParser(
    description='Script to update an SSL certificate on an AWS Elasitci Load Balancer')

parser.add_argument("-f", "--fully-qualified-domain-name", help="The SSL Certificte Fully Qualified Domain Name")
parser.add_argument("-c", "--certificate-path", help="Path to stored certificate.")

args = parser.parse_args()

def get_certificate_arn(fqdn):

    logging.info("Retrieving certificate list")

    certificate_list = subprocess.run(
        ["aws", "acm", "list-certificates"
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    certificates = json.loads(certificate_list)

    for certificate in certificates["CertificateSummaryList"]:

        if certificate["DomainName"] == fqdn:
            logging.info("Retrieved ARN")
            return certificate["CertificateArn"]

        else:
            sys.exit("Couldn't find ARN for this FQDN")


def update_ssl_cert(fqdn,arn,cert_path):

    logging.info("Updating AWS ELB with new certificate.")

    certificate = '/'.join([cert_path,fqdn,"cert.pem"])

    certificate_chain = '/'.join([cert_path,fqdn,"chain.pem"])

    private_key = '/'.join([cert_path,fqdn,"privkey.pem"])

    print(private_key)

    try:
        update_certificate = subprocess.run(
            ["aws","acm", "import-certificate",
             "--certificate-arn", arn,
             "--certificate", "file://" + certificate,
             "--certificate-chain", "file://" + certificate_chain,
             "--private-key", "file://" + private_key
             ],
            stdout=subprocess.PIPE,
            check=True
        )

        logging.info("Certificate updated")

    except subprocess.CalledProcessError:
        sys.exit("There was an error updating the AWS ELB SSL certificate.")

arn = get_certificate_arn(args.fully_qualified_domain_name)

update_ssl_cert(args.fully_qualified_domain_name, arn, args.certificate_path)
