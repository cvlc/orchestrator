#!/bin/bash
if [[ "$1" ]]; then 
ID=$(docker inspect "$1" | grep 'ID' | cut -d'"' -f4)
echo "ID: $ID"
RESULT=$(/usr/bin/curl -s -k --data "container_id=$ID&secret=abcdef" "https://127.0.0.1:8997/container" 2>/dev/null)
echo "Result:"
echo "$RESULT"
else
echo "ERROR"
exit
fi
