#!/bin/bash
# Extract information about the Instance
DNS_NAME=
DNS_ZONE_ID=
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4/)

# Update Route 53 Record Set based on the Name tag to the current Public IP address of the Instance
echo "Updating DNS record $DNS_NAME to point to $PUBLIC_IP..."
aws route53 change-resource-record-sets --hosted-zone-id $DNS_ZONE_ID --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'$DNS_NAME'","Type":"A","TTL":300,"ResourceRecords":[{"Value":"'$PUBLIC_IP'"}]}}]}'
