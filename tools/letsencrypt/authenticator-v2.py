#!/usr/bin/env python3

import os
import subprocess
import sys
import logging
import json

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

dns_names = json.loads(sys.argv[1])
resource_group = sys.argv[2]

for key,value in dns_names.items():

    host = value[0]
    zone = value[1]
    
    logging.info("host and zone =  %s.%s" % (host, zone))
    
    if host == "*" or host is None:
        logging.debug("host empty or requesting wildcard cert")
        acme_challenge_name = "_acme-challenge"
    else:
        acme_challenge_name = "_acme-challenge." + host

    logging.info("CERTBOT_DOMAIN =  %s" % (os.getenv("CERTBOT_DOMAIN")))
    
    if host is not None:
        host_domain = ".".join(value)
    else:
        host_domain = zone

    if host != "*" and host_domain != os.getenv("CERTBOT_DOMAIN"):
        continue

    cmd = ["az", "network", "dns", "record-set", "txt", "create",
         "--name", acme_challenge_name,
         "--resource-group", resource_group,
         "--zone-name", zone,
         "--ttl", "60"
         ]
    logging.info("Running: %s" % (" ".join(cmd)))
    create_record_set = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        check=True
    )

    cmd = ["az", "network", "dns", "record-set", "txt", "add-record",
         "--record-set-name", acme_challenge_name,
         "--resource-group", resource_group,
         "--zone-name", zone,
         "--value", os.getenv("CERTBOT_VALIDATION")
         ]
    logging.info("Running: %s" % (" ".join(cmd)))
    create_dns_record = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        check=True
    )
