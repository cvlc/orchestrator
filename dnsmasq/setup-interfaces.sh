#!/bin/bash
# A very simple script that creates two bridges, adds ULA addresses (please generate your own as per RFC 4193 (http://tools.ietf.org/html/rfc4193) or use your own global addresses.

BRIDGE0="fd39:9706:2786:6333::1/64"
BRIDGE1="fd39:9709:2766:6555::1/64"
LOCATION="/opt/orchestrator/dnsmasq"

# Docker bridge (internal)
brctl addbr br0
brctl setfd br0 0

# Device bridge (external)
brctl addbr br1
brctl setfd br1 0
# We can add external interfaces like so:
# brctl addif br1 eth0
# ip link set eth0 up

ip link set br0 up 
ip addr add "$BRIDGE0" dev br0

ip link set br1 up
ip addr add "$BRIDGE1" dev br1

# IPv4 addresses are not required but may be useful for external devices.
# ip addr add 10.6.6.1/24 dev br1

# Both internal-dhcp.sh and external-dhcp.sh need to be modified with the settings from Orchestrator.
# Likewise, see the dnsmasq-internal and -external configuration files to adjust address ranges.

dnsmasq -d --bind-dynamic --listen-address `echo $BRIDGE0 | cut -d'/' -f1` --dhcp-hostsfile="$LOCATION/int-staticaddr" -C "$LOCATION/dnsmasq-internal.conf" --dhcp-script="$LOCATION/internal-dhcp.sh" 2>&1 > internal-log &
dnsmasq -d --bind-dynamic --listen-address `echo $BRIDGE1 | cut -d'/' -f1`  --dhcp-hostsfile="$LOCATION/ext-staticaddr" -C "$LOCATION/dnsmasq-external.conf" --dhcp-script="$LOCATION/external-dhcp.sh" 2>&1 > external-log &

# We could also use hostapd to provide a wireless access point for devices, if we were sure to add the wireless device to br1 above and to bring it up.
#hostapd /etc/hostapd/DemoAP.conf &
