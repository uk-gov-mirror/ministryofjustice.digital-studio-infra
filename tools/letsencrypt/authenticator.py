#!/usr/bin/env python3

import os
import subprocess
import sys


log = "letsencrypt/azure-dns.log"

open(log, 'a').write("Setting TXT record for " +
                     os.getenv("CERTBOT_DOMAIN") + "\n")

hostname = sys.argv[1]
zone = sys.argv[2]
resource_group = sys.argv[3]

subprocess.run(
    ["az", "network", "dns", "record-set", "txt", "create",
     "--name", hostname,
     "--resource-group", resource_group,
     "--zone-name", zone,
     "--ttl", "60"
     ],
    stdout=subprocess.PIPE,
    check=True
).stdout.decode()

subprocess.run(
    ["az", "network", "dns", "record-set", "txt", "add-record",
     "--record-set-name", hostname,
     "--resource-group", resource_group,
     "--zone-name", zone,
     "--value", os.getenv("CERTBOT_VALIDATION")
     ],
    stdout=subprocess.PIPE,
    check=True
).stdout.decode()


# az network dns record-set txt create --name $CERTBOT_HOSTNAME --resource-group webops --zone-name hmpps.dsd.io --ttl 60
# az network dns record-set txt add-record --record-set-name $CERTBOT_HOSTNAME --resource-group webops --value $CERTBOT_VALIDATION --zone-name hmpps.dsd.io
