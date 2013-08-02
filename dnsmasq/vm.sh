#!/bin/bash
# This will generate a random mac address and boot a named QEMU disk image (you must create or obtain one).
# Changes to the VM image are not saved. 
BRIDGE=br1
IMAGE=debian.qcow2
MAC=$(dd bs=1 count=5 if=/dev/urandom 2>/dev/null | hexdump -v -e '/1 ":%02X"')
MAC="52$MAC"
echo $MAC
qemu-system-x86_64 -enable-kvm -hda $IMAGE -snapshot -net nic,macaddr=$MAC -net bridge,br=$BRIDGE 2>&1>/dev/null &
