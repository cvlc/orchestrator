#!/usr/bin/env ruby
require_relative './environment'

def unionize(container_id, secret_recv)
    if $secret == secret_recv
    p "Secret accepted"
    if `grep --quiet "#{container_id}" "./unionize-done"` == ''
        p "Not found in unionize-done"
        cgroup_unsanitized = $config['docker']['cgroup_dir']
        bridge_unsanitized = $config['docker']['bridge']
        random_unsanitized = `echo $RANDOM`
        
        cgroup = cgroup_unsanitized.chomp.strip # TODO: Further sanitization and below
        
        nspid_unsanitized = `head -n 1 "#{cgroup}/#{container_id}/tasks"`
        
        nspid = nspid_unsanitized.chomp.strip
        random = random_unsanitized.chomp.strip
        bridge = bridge_unsanitized.chomp.strip
        p "NSPID:#{nspid}!"
        p "CGROUP:#{cgroup}!"
        p "RANDOM:#{random}!"
        p "BRIDGE:#{bridge}!"

        `mkdir -p "/var/run/netns"`
        `rm -f "/var/run/netns/#{container_id}"`
        `ln -s "/proc/#{nspid}/ns/net" "/var/run/netns/#{container_id}"`
        if_local_name = "pvnet1" << random
        if_remote_name = "pvnet1r" << random
        p "LOCAL:#{if_local_name}!"
        p "REMOTE:#{if_remote_name}!"
        `/usr/bin/ip link add name #{if_local_name} type veth peer name #{if_remote_name}`
        `/usr/bin/brctl addif #{bridge} #{if_local_name}`
        `/usr/bin/ip link set #{if_local_name} up`
        `/usr/bin/ip link set #{if_remote_name} netns #{nspid}`
        # We need this to alias pvnet??? -> eth1 then bring the link up (past the first created container, links somehow don't go up)
        `/usr/bin/ip netns exec #{container_id} ip link set #{if_remote_name} name eth1`
        `/usr/bin/ip netns exec #{container_id} ip link set eth1 up`
        p "CONTAINER:#{container_id}!"
        p "Done"
        ipv6_address=`/usr/bin/ip netns exec #{container_id} ip -o -6 addr show dev eth1 | grep global | cut -d' ' -f7 | cut -d'/' -f1`
        return ipv6_address.chomp.strip
    end
    else
    p "Refused to /container, key validation failed."
    end
end
