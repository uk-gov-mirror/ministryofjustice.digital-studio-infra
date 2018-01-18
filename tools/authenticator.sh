#!/bin/bash

if [[ ! -f "test.log" ]]; then
      #echo -e "Making file "
      touch "test.log"
    fi
    echo "test" >> test.log


if [[ -z "$CERTBOT_DOMAIN" ]];then
echo "values not set" >> test.log

else
echo "trying to set txt record" >> test.log
az network dns record-set txt add-record --record-set-name _acme-challenge.example --resource-group webops --value $CERTBOT_VALIDATION --zone-name hmpps.dsd.io

fi
