#!/usr/bin/env ruby
require_relative './environment'

def unionize(container_id, secret_recv)
    if $secret == secret_recv
    p "Secret accepted"
    if `grep --quiet "#{container_id}" "./unionize-done"` == ''
        p "Not found in unionize-done"
        cgroup_unsanitized = $config['docker']['cgroup_dir']
        bridge_unsanitized = $config['docker']['bridge']
        pipework_unsanitized = $config['docker']['pipework']
        
        cgroup = cgroup_unsanitized.chomp.strip # TODO: Further sanitization and below
        p "Finding PID..."
        nspid_unsanitized = `head -n 1 "#{cgroup}/#{container_id}/tasks"` until nspid_unsanitized != nil

        nspid = nspid_unsanitized.chomp.strip
        bridge = bridge_unsanitized.chomp.strip
        pipework = pipework_unsanitized.chomp.strip
        p "NSPID:#{nspid}!"
        p "CGROUP:#{cgroup}!"
        p "BRIDGE:#{bridge}!"
         
        ipv6_address = ''
        container = ''

        container = IO.popen("/usr/bin/sudo #{pipework} #{bridge} #{container_id} dhcp")
        container.readlines

        IO.popen "/usr/bin/sudo /usr/bin/ip netns exec #{nspid} ip -o -6 addr show dev eth1 | grep global | cut -d' ' -f7 | cut -d'/' -f1 | head -n1 | tr '\n' ' '"  do |io|
           ipv6_address = io.read
        end

        p "IPv6 Address: #{ipv6_address}"
        p "Pipework: #{container}"
        p "Container ID: #{container_id}"
        p "Done"

        return ipv6_address.chomp.strip
    end
    else
    p "Refused to /container, key validation failed."
    end
end
