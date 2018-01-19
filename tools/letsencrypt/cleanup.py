#!/usr/bin/env python3

import os
import subprocess
import sys


log = "letsencrypt/azure-dns.log"

open(log, 'a').write("Deleting TXT record for " +
                     os.getenv("CERTBOT_DOMAIN") + "\n")

hostname = sys.argv[1]
zone = sys.argv[2]
resource_group = sys.argv[3]

subprocess.run(
    ["az", "network", "dns", "record-set", "txt", "remove-record",
     "--record-set-name", hostname,
     "--resource-group", resource_group,
     "--zone-name", zone,
     "--value", os.getenv("CERTBOT_VALIDATION")
     ],
    stdout=subprocess.PIPE,
    check=True
).stdout.decode()
