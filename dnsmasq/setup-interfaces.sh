#!/bin/bash
# A very simple script that creates two bridges, adds ULA addresses (please generate your own as per RFC 4193 (http://tools.ietf.org/html/rfc4193) or use your own global addresses.

#ip link set wlp2s0 down
brctl addbr br0
brctl addbr br1
brctl setfd br0 0
brctl setfd br1 0
#brctl addif br1 wlp2s0

#ip link set wlp2s0 up
ip link set br0 up
ip addr add fd39:9706:2786:6333::1/64 dev br0
ip link set br1 up
ip addr add fd39:9709:2766:6555::1/64 dev br1
ip addr add 10.6.6.1/24 dev br1

# Both internal-dhcp.sh and external-dhcp.sh need to be modified with the settings from Orchestrator.

dnsmasq -d --bind-dynamic --listen-address "fd39:9706:2786:6333::1" --dhcp-hostsfile="/home/$USER/orchestrator/dnsmasq/int-staticaddr" -C "/home/$USER/orchestrator/dnsmasq/dnsmasq-internal.conf" --dhcp-script="/home/$USER/orchestrator/dnsmasq/internal-dhcp.sh" 2>&1 > internal-log &

dnsmasq -d --bind-dynamic --listen-address "fd39:9709:2766:6555::1"  --dhcp-hostsfile="/home/$USER/orchestrator/dnsmasq/ext-staticaddr" -C "/home/$USER/orchestrator/dnsmasq/dnsmasq-external.conf" --dhcp-script="/home/$USER/orchestrator/dnsmasq/external-dhcp.sh" 2>&1 > external-log &

#hostapd /etc/hostapd/DemoAP.conf &
