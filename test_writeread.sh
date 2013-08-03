#!/bin/bash
# This script will introduce some example data to Orchestrator, testing data read/write/deletion operations.
ADDRESS="127.0.0.1"
PORT="8998"


echo "Creating Cloud service..."
SERVICE_ID=$(curl -s -k --data "service_address=ffff:ffff:ffff:ffff" https://$ADDRESS:$PORTcloud/add 2>/dev/null)
SERVICE_ID2=$(curl -s -k "https://$ADDRESS:$PORT/cloud/ffff:ffff:ffff:ffff" 2>/dev/null)
echo $SERVICE_ID
echo $SERVICE_ID2
echo "--------"
echo "Creating DHCP service..."
SERVICE2_ID=$(curl -s -k --data "service_address=aaaa:aaaa:aaaa:aaaa" https://$ADDRESS:$PORT/dhcp/add 2>/dev/null)
SERVICE2_ID2=$(curl -s -k "https://$ADDRESS:$PORT/dhcp/aaaa:aaaa:aaaa:aaaa" 2>/dev/null)
echo $SERVICE2_ID
echo $SERVICE2_ID2
echo "-------"

read -n 1
echo "Creating instance..."
INSTANCE_ID=$(curl -s -k --data "server_id=$SERVICE_ID&instance_address=abbb:cccc:dddd:eeee&instance_duid=1234567890" https://$ADDRESS:$PORT/instance/add 2>/dev/null)
echo $INSTANCE_ID
echo "-------"
echo "Instance list:"
INSTANCE_LIST=$(curl -s -k https://$ADDRESS:$PORT/instance 2>/dev/null)
echo $INSTANCE_LIST
echo "-------"

read -n 1
echo "Creating client..."
CLIENT_ID=$(curl -s -k --data "server_id=$SERVICE2_ID&client_address=bbbb:aaaa:dddd:eeee&client_duid=0987654321" https://$ADDRESS:$PORT/client/add 2>/dev/null)
echo $CLIENT_ID
echo "-------"
echo "Client list:"
CLIENT_LIST=$(curl -s -k https://$ADDRESS:$PORT/client 2>/dev/null)
echo $CLIENT_LIST
echo "-------"

read -n 1
echo "Client delete:"
CLIENT_RM=$(curl -s -k --data "client_address=bbbb:aaaa:dddd:eeee" https://$ADDRESS:$PORT/client/rm 2>/dev/null)
echo $CLIENT_RM
echo "------"
echo "Client list:"
CLIENT_LIST=$(curl -s -k https://$ADDRESS:$PORT/client 2>/dev/null)
echo $CLIENT_LIST
echo "-------"

read -n 1
echo "Instance delete:"
INSTANCE_RM=$(curl -s -k --data "instance_address=abbb:cccc:dddd:eeee" https://$ADDRESS:$PORT/instance/rm 2>/dev/null)
echo $INSTANCE_RM
echo "------"
echo "Instance list:"
INSTANCE_LIST=$(curl -s -k https://$ADDRESS:$PORT/instance 2>/dev/null)
echo $INSTANCE_LIST
echo "-------"

echo "Deleting Cloud service..."
SERVICE_RM=$(curl -s -k --data "service_address=ffff:ffff:ffff:ffff" https://$ADDRESS:$PORT/cloud/rm 2>/dev/null)
echo $SERVICE_RM
echo "--------"
echo "Deleting DHCP service..."
SERVICE2_RM=$(curl -s -k --data "service_address=aaaa:aaaa:aaaa:aaaa" https://$ADDRESS:$PORT/dhcp/rm 2>/dev/null)
echo $SERVICE2_RM
echo "-------"
echo "Cloud list:"
SERVICE_LIST=$(curl -s -k https://$ADDRESS:$PORT/cloud 2>/dev/null)
echo $SERVICE_LIST
echo "-------"
echo "DHCP list:"
SERVICE2_LIST=$(curl -s -k https://$ADDRESS:$PORT/dhcp 2>/dev/null)
echo $SERVICE2_LIST
echo "-------"
