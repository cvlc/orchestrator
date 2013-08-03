#!/bin/bash
# This will test the plugin helper by starting an identified container (provide the container shortID as the argument)

SECRET="abcdef"
ADDRESS="127.0.0.1"
PORT="8997"

if [[ "$1" ]]; then 
ID=$(docker inspect "$1" | grep 'ID' | cut -d'"' -f4)
echo "ID: $ID"
RESULT=$(/usr/bin/curl -s -k --data "container_id=$ID&secret=$SECRET" "https://$ADDRESS:$PORT/container" 2>/dev/null)
echo "Result:"
echo "$RESULT"
else
echo "ERROR"
exit
fi
