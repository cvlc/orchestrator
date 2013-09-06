# Orchestrator v0.1
## Introduction
Orchestrator is a modular, extensible backend framework for automated provisioning of virtual resources for IPv6 clients using stateful DHCPv6. Currently it
supports the DNSMasq DHCPv6 server and Docker.io for the provision of virtual instances. This is a very early build of the application, it will contain bugs and
can be considered in a pre-alpha or 'development' state. 

## Requirements
* [Ruby 1.9](https://github.com/ruby/ruby)
* [ParseConfig](https://github.com/derks/ruby-parseconfig)
* [Sequel](https://github.com/jeremyevans/sequel/)
* [Sinatra](https://github.com/sinatra/sinatra/)
* [docker-api](https://github.com/swipely/docker-api)
* [facets](https://github.com/rubyworks/facets/)

## Documentation

...is currently non-existent, but running the orchestrator.rb file as a user on the management node and the unionize.rb file as root on the Docker node will start the software itself.

To see how to run DNSMasq on both the Docker (internal) and external-facing nodes, refer to 'dnsmasq/setup-interfaces.sh' for a single node example. Be sure to read 'Notes' below.

## Current Objectives

* Refactoring/debugging so everything works consistently
* Documentation
* Database persistence (currently half-implemented)
* Proper Ruby packaging

## Future Goals 

* Additional plugins for a mix of DHCPv6/Cloud providers
* OpenStack integration
* More networking/firewall options (eg. complex backend networks of containers for each client)

## Notes

* For DHCPv6 to work on Docker containers, the base image and command combination used must start a DHCPv6 client and request an IPv6 address via eth1 (from the container's perspective)

* Unionize.rb is a modified version of unionize.sh, a versatile networking script for Docker written by Jérôme Petazzoni (jpetazzo), who has also contributed to an excellent OpenStack backend for Docker (dotcloud/openstack-docker). 

* The program is assumed to reside within /home/$USER/orchestrator. If this is not the case, paths in many of the bash scripts and settings files will have to be adjusted.
