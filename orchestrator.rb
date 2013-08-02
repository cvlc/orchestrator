#!/usr/bin/env ruby
require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'sinatra/json'
require 'sequel'
require './lib/environment.rb'
require './plugins/service/generic-service'
require './plugins/service/dnsmasq-service'
require './plugins/service/docker-service'
require './plugins/client/generic-client'
require './plugins/client/docker-client'

CERT_PATH = $config['cert']['path']

webrick_options = {
        :BindAddress        => $config['web']['address'],
        :Port               => $config['web']['port'],
        :Logger             => WEBrick::Log::new($stderr, 
WEBrick::Log::DEBUG),
        :DocumentRoot       => "./public",
        :SSLEnable          => true,
        :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
        :SSLCertificate     => OpenSSL::X509::Certificate.new(  
File.open(File.join(CERT_PATH, $config['cert']['cert'])).read),
        :SSLPrivateKey      => OpenSSL::PKey::RSA.new(          
File.open(File.join(CERT_PATH, $config['cert']['key'])).read),
        :SSLCertName        => [ [ "CN",WEBrick::Utils::getservername ] 
]
}

if $config['sql']['init'] == "true"
    DB.create_table! :services do
        primary_key :id
        String :identifier
        String :address
        String :type
    end
    DB.create_table! :clients do
        primary_key :id
        String :identifier
        String :address
        String :duid
        String :type
        Integer :state
    end
    DB.create_table! :client_map do
        primary_key :id
        Integer :client_id
        Integer :instance_id
    end
    DB.create_table! :service_map do
        primary_key :id
        Integer :service_id
        Integer :client_id
    end
else
    DB[:services].each{ |s| if s[:type] == "DHCP" then Service::DNSMasq.new(s[:address], s[:type], s[:identifier]) elsif s[:type] == "Cloud" then Service::Docker.new(s[:address], s[:type], s[:identifier]) end }
    DB[:service_map].each{ |m| servicedb = Database::Service.byDBID(m[:service_id]); clientdb = Database::Client.byDBID(m[:client_id]); service = Service::DNSMasq.byId(servicedb[:identifier]); if service != true then service.addclient(Client::Generic.byId(clientdb[:identifier])) end}
    DB[:clients].each{ |c| if c[:type] == "Device" then Client::Generic.new(c[:address], c[:duid], c[:type], c[:server_id], c[:identifier]) elsif c[:type] == "Instance" then Client::Generic.new(c[:address], c[:duid], c[:type], c[:identifier]) end }
    DB[:client_map].each{ |m| clientdb = Database::Client.byDBID(m[:client_id]); instancedb = Database::Client.byDBID(m[:instance_id]); client = Client::Generic.byId(clientdb[:identifier]); if client != true then client.adopt(Client::Generic.byId(m[:instance_id])) end }
end

class Orchestrator < Sinatra::Base
    get '/' do
      "Orchestrator v0.1"
    end

    post '/dhcp/add' do
      service_address = params[:service_address]
      service_type = "DHCP"
      service = Service::DNSMasq.new(service_address, service_type)
      "#{service.id}"
    end

    post '/dhcp/rm' do
      service_address = params[:service_address]
      service_type = "DHCP"
      service = Service::DNSMasq.byAddr(service_address, service_type)
      service.rm()
      "#{service_address}"
    end

    get '/dhcp' do
    "#{Service::DNSMasq.ls("DHCP")}"
    end

    get '/dhcp/:name' do
      service_address = params[:name]
      service_type = "DHCP"
      service = Service::DNSMasq.byAddr(service_address, service_type)
      if service.to_s == 'false'
        service_id = 'false'
      else
        service_id = service.id
      end
      "#{service_id}"
    end

    post '/client/add' do
    server_id = params[:server_id]
    device_address = params[:client_address]
    device_duid = params[:client_duid]
    device_type = "Device"
    client = Client::Generic.new(device_address, device_duid, device_type)
    server = Service::DNSMasq.byId(server_id)
    begin
    server.addclient(client)
    rescue
      puts "ERROR: No such server."
      client.rm()
      raise TypeError
    end
    # TODO: Expand to use ClientMap and adopt()/dadopt() to directly map clients/instances and instances/containers
    container_ip = Client::Docker.provision()
      "#{client.id}/#{container_ip}"
    end

    post '/client/up' do
    server_id = params[:server_id]
    device_address = params[:client_address]
    device_duid = params[:client_duid]
    device = Client::Generic.byAddr(device_address)
    device.on()
    end
    post '/client/rm' do
    server_id = params[:server_id]
    device_address = params[:client_address]
    device_type = "Device"
    client = Client::Generic.byAddr(device_address,device_type)
    client.rm()
      "#{device_address}"
    end
    
    get '/client' do
    "#{Client::Generic.ls("Device")}"
    end

    get '/client/:name' do
      device_address = params[:name]
      device_type = "Device"
      client = Client::Generic.byAddr(device_address, device_type)
      if client.to_s == 'false'
        client_id = 'false'
      else
        client_id = client.id
      end
      "#{client_id}"
    end

    post '/cloud/add' do
      service_address = params[:service_address]
      service_type = "Cloud"
      cloud = Service::Docker.new(service_address, service_type)
      "#{cloud.id}"
    end

    post '/cloud/rm' do
      service_address = params[:service_address]
      service_type = "Cloud"
      cloud = Service::Docker.byAddr(service_address, service_type)
      cloud.rm()
      "#{service_address}"
    end

    get '/cloud' do
      "#{Service::Docker.ls("Cloud")}"
    end

    get '/cloud/:name' do
    service_address = params[:name]
    service_type = "Cloud"
    cloud = Service::Docker.byAddr(service_address, service_type)
      if cloud.to_s == 'false'
        cloud_id = 'false'
      else
        cloud_id = cloud.id
      end
      "#{cloud_id}"
    end

    post '/instance/add' do
    server_id = params[:server_id]
    instance_address = params[:instance_address]
    instance_duid = params[:instance_duid]
    instance_type = "Instance"
    instance = Client::Docker.new(instance_address, instance_duid, instance_type)
    cloud = Service::Docker.byId(server_id)
    begin
    cloud.addclient(instance)
    rescue 
      puts "ERROR: No such server."
      instance.rm()
    end
      "#{instance.id}"
    end

    post '/instance/rm' do
    instance_address = params[:instance_address]
    instance_type = "Instance"
    instance = Client::Docker.byAddr(instance_address, instance_type)
    instance.rm()
      "#{instance_address}"
    end

    get '/instance' do
    "#{Client::Docker.ls("Instance")}"
    end

    post '/instance/up' do
    server_id = params[:server_id]
    instance_address = params[:client_address]
    instance_duid = params[:client_duid]
    instance = Client::Docker.byAddr(device_address)
    instance.on()
    end
    get '/instance/:name' do
    instance_address = params[:name]
    instance_type = "Instance"
    instance = Client::Docker.byAddr(instance_address, instance_type)
      if instance.to_s == 'false'
        instance_id = 'false'
      else
        instance_id = instance.id
      end
      "#{instance_id}"
    end


#    post '/map/add' do
#    instance_id = params[:instance_id]
#    device_id = params[:device_id]
#    instance = Client::Docker.byId(instance_id)
#    device = Client::Generic.byId(device_id)
#    p instance
#    p device
#    device.adopt(instance)
#      "#{device} + #{instance}"
#    end

#    post '/map/rm' do
#    instance_id = params[:instance_id]
#    device_id = params[:device_id]
#    instance = Client::Generic.byId(instance_id)
#    device = Client::Generic.byId(device_id)
#    device.disown(instance)
#      "#{device} - #{instance}"
#    end

#    get '/map' do
#      "#{Database::ClientInstance.ls()}"
#    end

#    get '/map/:name' do
#        "Unimplemented." # if instance then, else if client...
#    end

#    post '/associate/add' do
#    client_id = params[:client_id]
#    service_id = params[:server_id]
#    
#    service = Service::DNSMasq.byId(service_id)
#    client = Client::Generic.byId(client_id)
#    service.addclient(client)
#      "#{service} + #{client}"
#    end

#    post '/associate/rm' do 
#    client_id = params[:client_id]
#    service_id = params[:server_id]

#    service = Service::DNSMasq.byId(service_id)
#    client = Client::Generic.byId(client_id)
#    service.rmclient(client)
#      "#{service} - #{client}"
#    end

#    get '/associate' do
#      "#{Database::ClientService.ls()}"
#    end

#    get '/associate/:name' do
#        "Unimplemented." # if service then, else if client....
#    end
end

Rack::Handler::WEBrick.run Orchestrator, webrick_options
