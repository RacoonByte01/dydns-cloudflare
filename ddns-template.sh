#!/bin/sh
CLOUDFLARE_EMAIL='' 			# Your email login in cloudflare
CLOUDFLARE_API_KEY='' 			# Global token API Token
ZONE_ID='' 						# Can be found in the "Overview" tab of your domain
TTL=1 							# Set the DNS TTL (seconds) 1 = auto
NAMES=('' '') 					# Titles of sites ('google.com' 'youtube.google.com' '...')
PROXIEDS=('' '') 				# Set the proxy to true or false of titles ('true' 'false' 'true' '...')
TYPES=('' '') 					# Set the types of  of titles ('A' 'AAAA' '...')
FILE_MD5_IP='MD5.IP' 			# Path of md5 ip file

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
## Get if new and old ip are the same
###########################################
is_old_equals_new_ip()
{
        if [ ! -f $FILE_MD5_IP ]; then
                echo 'Do not have any ip save generate new ip md5 file...'
                echo $(echo $IP | md5sum | awk '{printf $1}') >> $FILE_MD5_IP
                echo 'Generated.'
                echo 1
        else
                if [[ "$(echo $IP | md5sum | awk '{printf $1}')" == "$(cat $FILE_MD5_IP)" ]]; then
                        echo 0
                else
                        echo 1
                fi
        fi
}

###########################################
## Get Cloudflare DNS RECORD ID by the name
###########################################
get_dns_record_id()
{
	local DNS_RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$1" \
			-H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
			-H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
			-H "Content-Type: application/json" )
	echo "$DNS_RECORD" | sed -E 's/.*"id":"([A-Za-z0-9_]+)".*/\1/'
}

###########################################
## Cloudflare updater from oficial [webside](https://developers.cloudflare.com/api/resources/dns/subresources/records/methods/edit/)
###########################################
send_info ()
{
	for ((i = 0; i < ${#NAMES[@]}; i++)); do
		curl https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$(shift; get_dns_record_id ${NAMES[$i]}) \
			-X PATCH \
			-H 'Content-Type: application/json' \
			-H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
			-H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
			-d "{
				\"name\": \"${NAMES[$i]}\",
				\"ttl\": $TTL,
				\"type\": \"${TYPES[$i]}\",
				\"comment\": \"$(date +'%Y-%m-%d %H:%M:%S')\",
				\"content\": \"$IP\",
				\"proxied\": ${PROXIEDS[$i]}
			}" &> /dev/null &
	done
}

get_public_ip
if [[ "$(is_old_equals_new_ip)" == "1" ]]; then 
	echo Sending info...
	send_info
fi
