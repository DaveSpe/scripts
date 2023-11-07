#!/bin/bash
# Script uses the Cloudflare API, create a token in your dns zone with: Zone.Zone Settings, Zone.Zone, Zone.DNS permissions.
# Cloudflare specific variables
# indentifier value can be obtained by running the following shell command using your api token:
# curl --request GET --url https://api.cloudflare.com/client/v4/zones/<zone_identifier>/dns_records/ -H "Authorization: Bearer <api_token>" -H "Content-Type:application/json" | jq .result
api_token=<api_token>
zone_identifier=<zone_identifier>
identifier=<identifier>
domain_name="<your-domain>" # ex. "*.my-domain.com"

# fetch current public IP
my_ip=$(curl -s ifconfig.me)
# fetch public IP registered with Cloudflare
cf_ip=$(curl -s --request GET --url https://api.cloudflare.com/client/v4/zones/${zone_identifier}/dns_records/${identifier} -H "Authorization: Bearer "${api_token} -H "Content-Type:application/json" | jq .result.content | tr -d '"')

# Check to see if DNS is working, this can be omited if DNS is not in a container on your server
if [[ $my_ip == "" || $cf_ip == "" ]]
then
    echo "IP is empty, restarting DNS container!"
    docker restart $dns_container
fi

if [[ $my_ip == $cf_ip ]] 
then
    echo "Public IP matches Cloudflare IP"
else
    echo "Updating IP within Cloudflare from: $cf_ip, to: $my_ip"
    # Update and register result of update
    result=$(curl -s --request PUT --url https://api.cloudflare.com/client/v4/zones/${zone_identifier}/dns_records/${identifier} -H "Content-Type: application/json" -H "Authorization: Bearer ${api_token}" -d '{"content": "'${my_ip}'", "name": "'${domain_name}'", "proxied": false, "type": "A", "tags": [], "ttl": 1}' | jq .success)
    # echo "result: "$result # debug
    if [[ $result == true ]]
    then
        echo "DNS updated successfully"
    else
        echo "Failed to update DNS with new IP"
    fi
fi
