#!/bin/bash
# This can be used to kill any running DNSMasq and remove lease files.
killall dnsmasq
echo>`pwd`/ext-staticaddr
echo>`pwd`/int-staticaddr
rm /tmp/internal.leases
rm /tmp/external.leases

