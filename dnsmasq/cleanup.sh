#!/bin/bash
killall dnsmasq
echo>/home/calum/orchestrator/dnsmasq/ext-staticaddr
echo>/home/calum/orchestrator/dnsmasq/int-staticaddr
rm /tmp/internal.leases
rm /tmp/external.leases

