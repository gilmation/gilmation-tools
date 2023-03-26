#!/bin/bash
#
# Check the ssl certs for a list of sites
#

sites=''

for s in $sites; do
  target="https://www.$s/contacts"
  #echo
  #echo "Checking [$target]"
  #echo
  status=$(curl -s -o /dev/null -w '%{http_code}' $target)
  echo "Status for [$target] was [$status]"
  #echo
  #echo "------------------"
done
