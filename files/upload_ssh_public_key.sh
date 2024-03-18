#!/bin/bash
#PASSWORD=${controller-default-password}
#CONTROLLER_ADDRESS=${self.network_interface.0.access_config.0.nat_ip}
PASSWORD=
CONTROLLER_ADDRESS=

usage()
{
    echo "usage: upload_ssh_public_key.sh [[[--password password ] [--controller-address address] [--ssh-public-key ssh_public_key]] | [--help]]"
}

while [ "$1" != "" ]; do
    case $1 in
        --password )            shift
                                PASSWORD=$1
                                ;;
        --controller-address )  shift  
                                CONTROLLER_ADDRESS=$1
                                ;;
        --ssh-public-key )      shift  
                                SSH_PUBLIC_KEY=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

until $(curl -k -X GET --output /dev/null --silent --head --fail https://$CONTROLLER_ADDRESS); do
    sleep 10
done
# Login to the Controller with the default credentials and save the session cookies
COOKIE=$(curl -k --silent --output /dev/null -c - --location --request POST "https://$CONTROLLER_ADDRESS/login" --form username="admin" --form password="$PASSWORD")
# Setup CSRF Token Cookie
TOKEN=$(echo $COOKIE |  grep -o -E '.csrftoken.{0,33}' | sed -e 's/^[ \t]*csrftoken[ \t]//')
# Setup avi-sessionid Cookie
SESSIONID=$(echo $COOKIE | grep -o -E '.avi-sessionid.{0,33}' | sed -e 's/^[ \t]*avi-sessionid[ \t]//')
# Upload SSH Private Key
curl -v -k --location --request POST "https://$CONTROLLER_ADDRESS/api/adminkey" \
--header "x-csrftoken: $TOKEN" \
--header "referer: https://$CONTROLLER_ADDRESS/" \
--header 'Content-Type: application/json' \
--header "Cookie: csrftoken=$TOKEN; avi-sessionid=$SESSIONID; sessionid=$SESSIONID" \
--data "{\"key\": \"$SSH_PUBLIC_KEY\"}"
