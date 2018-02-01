#!/usr/bin/env python3

import os
import subprocess
import sys
import logging

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

hostname = sys.argv[1]
zone = sys.argv[2]
resource_group = sys.argv[3]

delete_dns_record = subprocess.run(
    ["az", "network", "dns", "record-set", "txt", "remove-record",
     "--record-set-name", hostname,
     "--resource-group", resource_group,
     "--zone-name", zone,
     "--value", os.getenv("CERTBOT_VALIDATION")
     ],
    stdout=subprocess.PIPE,
    check=True
)

if delete_dns_record.returncode == 0:
    logging.info("Deleted DNS record for %s.%s" % (hostname, zone))
else:
    logging.warn("Error deleting DNS record for %s.%s" % (hostname, zone))
