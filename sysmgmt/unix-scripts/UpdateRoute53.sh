#!/bin/bash

# Place in /var/lib/cloud/scripts/per-boot/ with global execute permissions.

# Extract information about the instance.
# DNS_NAME = needs to be a FQDN
DNS_NAME=
DNS_ZONE_ID=
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4/)

# Update Route 53 record.
echo "Updating DNS record $DNS_NAME to point to $PUBLIC_IP..."
aws route53 change-resource-record-sets --hosted-zone-id $DNS_ZONE_ID --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'$DNS_NAME'","Type":"A","TTL":300,"ResourceRecords":[{"Value":"'$PUBLIC_IP'"}]}}]}'
