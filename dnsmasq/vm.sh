#!/bin/bash

mac=$(dd bs=1 count=5 if=/dev/urandom 2>/dev/null | hexdump -v -e '/1 ":%02X"')
mac="52$mac"
echo $mac
qemu-system-x86_64 -enable-kvm -hda debian.qcow2 -snapshot -net nic,macaddr=$mac -net bridge,br=br1 2>&1>/dev/null &
