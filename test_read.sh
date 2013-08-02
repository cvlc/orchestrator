#!/bin/bash
# This script is useful for quickly listing all the components that Orchestrator is keeping track of.
echo "Instance list:"
INSTANCE_LIST=$(curl -s -k https://127.0.0.1:8998/instance 2>/dev/null)
echo $INSTANCE_LIST
echo "-------"
echo "Client list:"
CLIENT_LIST=$(curl -s -k https://127.0.0.1:8998/client 2>/dev/null)
echo $CLIENT_LIST
echo "-------"
echo "Cloud list:"
SERVICE_LIST=$(curl -s -k https://127.0.0.1:8998/cloud 2>/dev/null)
echo $SERVICE_LIST
echo "-------"
echo "DHCP list:"
SERVICE2_LIST=$(curl -s -k https://127.0.0.1:8998/dhcp 2>/dev/null)
echo $SERVICE2_LIST
echo "-------"
