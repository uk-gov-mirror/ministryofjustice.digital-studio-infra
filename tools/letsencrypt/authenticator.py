#!/usr/bin/env python3

import os
import subprocess
import sys
import logging

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

hostname = sys.argv[1]
zone = sys.argv[2]
resource_group = sys.argv[3]

create_record_set = subprocess.run(
    ["az", "network", "dns", "record-set", "txt", "create",
     "--name", hostname,
     "--resource-group", resource_group,
     "--zone-name", zone,
     "--ttl", "60"
     ],
    stdout=subprocess.PIPE,
    check=True
)

if create_record_set.returncode == 0:

    logging.info("Created DNS record set for %s.%s" % (hostname, zone))

    create_dns_record = subprocess.run(
        ["az", "network", "dns", "record-set", "txt", "add-record",
         "--record-set-name", hostname,
         "--resource-group", resource_group,
         "--zone-name", zone,
         "--value", os.getenv("CERTBOT_VALIDATION")
         ],
        stdout=subprocess.PIPE,
        check=True
    )
    if create_dns_record.returncode == 0:
        logging.info("Created DNS record for %s.%s" % (hostname, zone))
    else:
        logging.warn("Error updating DNS record for %s.%s" % (hostname, zone))
else:
    logging.warn("Error creating DNS record set for %s.%s" %
                 (hostname, zone))
