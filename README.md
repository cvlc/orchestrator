# Orchestrator v0.2
## Introduction
Orchestrator is a modular, extensible backend framework for automated provisioning of virtual resources for IPv6 clients using stateful DHCPv6. Currently it
supports the DNSMasq DHCPv6 server and Docker.io for the provision of virtual instances. This is a very early build of the application, it will contain bugs and
can be considered in a pre-alpha or 'development' state. 

## Possible Use cases
* Snapchat-like document or code sharing via web applications and container self-destruct timers
* Interactive demonstrations for hackerspaces and conferences - a user can personalize their own instance of your application, you could even export the resulting image and send it to them after!
* Automated server resource assignment for a personal cloud or [Internet of Things](http://resin.io/docker-on-raspberry-pi/)
* A fully destructable-on-demand personal [VPN](https://github.com/jpetazzo/dockvpn) for every client!

And many, many more!

## Requirements
* [Ruby 2.0.0](https://github.com/ruby/ruby)
* [ParseConfig](https://github.com/derks/ruby-parseconfig)
* [Sinatra](https://github.com/sinatra/sinatra/)
* [Sinatra-contrib](http://www.sinatrarb.com/contrib/)
* [docker-api](https://github.com/swipely/docker-api)
* [facets](https://github.com/rubyworks/facets/)
* [docker](http://www.docker.io)
* [dnsmasq](http://www.thekelleys.org.uk/dnsmasq)
* [dhcpcd](http://roy.marples.name/projects/dhcpcd)

## Optional
* [Sequel](https://github.com/jeremyevans/sequel/) and your SQLd of choice

## Documentation

There are three primary components to the service:

1. DNSMasq configurations and bash scripts (./dnsmasq)

2. unionize.rb with pipework (./docker)

3. orchestrator.rb and plugins (.)

### STEP 1 - DHCPv6:

To deploy Orchestrator, begin by configuring two bridge devices - the first bridge (br0 in the provided example configuration) connects client devices to the host running orchestrator.rb,
this can be logical or physical. The second bridge (br1) will be a logical device used to network Docker containers and should reside on the Docker host. Additionally, ensure that IPv6 forwarding is enabled on both hosts.

```
[user@orchestrator /opt]$ git clone https://github.com/cvlc/orchestrator.git
$ cd orchestrator
$ bundle install
# Wait for the gems to install
$ sudo sysctl -w net.ipv6.conf.all.forwarding=1
$ sudo brctl addbr br0
$ sudo brctl setfd br0 0
$ sudo brctl addif br0 eth0
$ sudo ip link set eth0 up
$ sudo ip link set br0 up
$ sudo ip -6 addr add fd39:9706:2786:6333::1/64 dev br0
```

```
[user@docker /opt]$ git clone https://github.com/cvlc/orchestrator.git
$ cd orchestrator
$ bundle install
# Wait for the gems to install
$ cd docker
$ sudo sysctl -w net.ipv6.conf.all.forwarding=1
$ sudo brctl addbr br1
$ sudo brctl setfd br1 0
$ sudo ip link set br1 up
$ sudo ip -6 addr add fd39:9709:2766:6555::1/64 dev br1
```

NOTE: Use your own IPv6 subnets or generate some [unique ULAs](https://www.ultratools.com/tools/rangeGenerator)!

Next, configure internal-dhcp.sh and dnsmasq-internal.conf on the orchestrator host and the 'external' counterparts on the docker host. Note that HOST and PORT in both DNSMasq scripts refer to the orchestrator node only. ADDRESS, however, should be the correct IPv6 address for each bridge. In the above dual-node configuration, the internal script would have a 'HOST' of 'localhost' and the external script would have 'HOST' set to "fd39:9706:2786:6333::1", presuming that this address is routed and reachable from the docker node.

Once the addresses are correctly configured, start DNSMasq on both hosts:
```
$ screen -S dnsmasq
$ cd /opt/orchestrator/dnsmasq
[user@orchestrator dnsmasq]$ sudo dnsmasq -d --bind-dynamic --listen-address "fd39:9706:2786:6333::1" --dhcp-hostsfile="/opt/orchestrator/dnsmasq/int-staticaddr" -C "/opt/orchestrator/dnsmasq/dnsmasq-internal.conf" --dhcp-script="/opt/orchestrator/dnsmasq/internal-dhcp.sh"
# CTRL+a then d to detach from screen
```
```
screen -S dnsmasq
cd /opt/orchestrator/dnsmasq
[user@docker dnsmasq]$ sudo dnsmasq -d --bind-dynamic --listen-address "fd39:9709:2766:6555::1" --dhcp-hostsfile=/opt/orchestrator/dnsmasq/ext-staticaddr" -C "/opt/orchestrator/dnsmasq/dnsmasq-external.conf" --dhcp-script="/opt/orchestrator/dnsmasq/external-dhcp.sh"
# CTRL+a then d to detach from screen
```

### STEP 2 - Unionize.rb with Docker:

The next module to configure is unionize.rb - this should be conducted on the docker host, on which the docker daemon is installed and running. Note that Docker should be listening on a network port. Check the output of `netstat -pant` on the docker host to verify the address/port that docker is listening on and configure docker/settings.cfg accordingly. If this is a multi-node deployment, ensure that a public address is set under [web] in settings.cfg so the orchestrator can connect to unionize.rb. Finally, change the 'shared secret' to something truly secret (the output of `pwgen -s 32 1` should suffice - keep a copy of this for the next step) and [generate a private key and certificate](http://www.akadia.com/services/ssh_test_certificate.html).

Before we can utilize pipework, we need to clone the submodule - navigate to the docker directory and update the pipework submodule.

```
[user@docker dnsmasq]$ cd ../docker
$ vim settings.cfg
# Modify configuration as appropriate
$ git submodule init
$ git submodule update
$ ls pipework
LICENSE   README.md   pipework
```

If you don't have a custom Docker image prepared already, take this opportunity to build the provided Dockerfile. This will provide a very basic container with SSH access and a default nginx configuration. Be sure to replace the public key in the Dockerfile with your own!

```
[user@docker docker]$ cd client
$ vim Dockerfile
# Replace public key with your own or a newly created one (ssh-keygen)
$ docker build -t orchestrator/client .
# Wait for docker to finish building the image
$ cd ..
```

Finally, we can start unionize.rb on the Docker host. Be sure that either the user running unionize.rb has sudo permissions without providing a password or you'll have to run unionize.rb as root:

```
[user@docker docker]$ screen -S unionize
$ bundle exec ruby unionize.rb
```

This command should provide various debugging information concerning the certificate then display a similar message to '[2013-10-10 10:00:00] INFO WEBrick::HTTPServer#start: pid=1234 port=8897'. If this is not the case, re-verify your configuration.

### STEP 3 - Orchestrator:

Move back to the Orchestrator host. Copy over the certificate, private key and secret string from the Docker host and apply them to orchestrator/settings.cfg (not docker/settings.cfg!) on the orchestrator host. Ensure that a public IP address is set for 'address' under '[web]' and that the docker host's IP ('helper_address') is set correctly under '[docker]'. If SQL is desired, ensure that the 'sequel' gem is installed, that 'enabled' and 'init' under '[sql]' are 'true' (remember to change 'init' to 'false' after the first execution if persistance is desired!) and set the connection string accordingly. The database must exist, but the tables will be created automatically if 'init' is 'true'. 

```
[user@orchestrator orchestrator]$ vim settings.cfg
# Configure as appropriate
```

Once orchestrator is configured, it's time to complete the installation! Simply execute orchestrator.

```
[user@orchestrator orchestrator]$ screen -S orchestrator
$ bundle exec ruby orchestrator.rb
```

Output should be similar to that given by unionize.rb - if the application immediately exists, re-check the configuration files. 

To see orchestrator in action, simply connect a client (see dnsmasq/vm.sh for an example with QEMU, install Debian and a DHCP client to debian.qcow2 and start the script multiple times for multiple virtual clients) and wait for notification of a newly started Docker container from DNSMasq, orchestrator or unionize.rb. 

## Current Objectives

* Refactoring/debugging to make the code nicer
* Database persistence (currently missing for Docker plugin)
* Proper Ruby packaging

## Future Goals 

* Additional plugins for a mix of DHCPv6/Cloud providers
* OpenStack integration
* More networking/firewall options (eg. complex backend networks of containers for each client)

## Notes

* An example Dockerfile is included in ./docker/client - you can 'docker build -t orchestrator/client .' in this directory to create the 'orchestrator/client' docker image for testing, it will provide an SSH server and default nginx installation. Be sure to replace the included pubkey with your own!

* Unionize.rb is a Ruby+Sinatra DSL wrapper to Pipework, a versatile networking script for Docker written by Jérôme Petazzoni ([jpetazzo](https://github.com/jpetazzo)), who has also contributed to an excellent OpenStack backend for Docker (dotcloud/openstack-docker). Be sure to 'git submodule init' and 'git submodule update' to get the latest forked version of pipework. 

* The directory is assumed to reside at (or should be softlinked to) /opt/orchestrator. If this is not the case, paths in many of the bash scripts and settings files will have to be adjusted.
