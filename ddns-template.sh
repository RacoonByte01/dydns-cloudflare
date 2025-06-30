#!/bin/sh
CLOUDFLARE_EMAIL='' 			# Your email login in cloudflare
CLOUDFLARE_API_KEY='' 			# Token for Scoped API Token
ZONE_ID='' 						# Can be found in the "Overview" tab of your domain
DNS_RECORD_ID='' 				# Which record you want to be synced
TTL=3600 						# Set the DNS TTL (seconds)
NAMES=('' '') 					# Titles of sites ('google.com' 'youtube.google.com' '...')
PROXIEDS=('' '') 				# Set the proxy to true or false of titles ('true' 'false' 'true' '...')
TYPES=('' '') 					# Set the types of  of titles ('A' 'AAAA' '...')

###########################################
## Get public ip
###########################################
get_public_ip () 
{
	local IP_SERVICES=('https://api.ipify.org' 'https://ipv4.icanhazip.com' 'https://ipinfo.io/ip') # public ip services
	local COMMAND_SEND=''

	for ((i = 0; i < ${#IP_SERVICES[@]}; i++)); do
		COMMAND_SEND="$COMMAND_SEND""curl '${IP_SERVICES[$i]}'"
		if [[ $i != $((${#IP_SERVICES[@]}-1)) ]]; then
			COMMAND_SEND="$COMMAND_SEND || "
		fi
	done
	IP=$(sh -c "$COMMAND_SEND")
}

###########################################
## Cloudflare updater from oficial [webside](https://developers.cloudflare.com/api/resources/dns/subresources/records/methods/edit/)
###########################################
send_info ()
{
	for ((i = 0; i < ${#NAMES[@]}; i++)); do
		curl https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID \
			-X PATCH \
			-H 'Content-Type: application/json' \
			-H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
			-H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
			-d "{
				\"name\": \"${NAMES[$i]}\",
				\"ttl\": $TTL,
				\"type\": \"${TYPES[$i]}\",
				\"comment\": \"Updated by script\",
				\"content\": \"$IP\",
				\"proxied\": ${PROXIEDS[$i]}
			}"
	done
}

get_public_ip
