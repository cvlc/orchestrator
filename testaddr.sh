#!/bin/bash
for link in /var/run/netns/*; do
longid=`echo $link | cut -d'/' -f5`
sudo ip netns exec $longid ip addr show dev eth1
done
