require 'sequel'
require 'logger'
require './lib/environment'

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

module Database
    $services_db = DB[:services]
    $clients_db = DB[:clients]
    $client_map_db = DB[:client_map]
    $service_map_db = DB[:service_map]
    class Client
        def self.new(client)
            if Database::Client.find(client) == true then
            raise TypeError 
            else 
            $clients_db.insert(:identifier => client.id, :address => client.client_address, :duid => client.client_duid, :type => client.client_type)
            end
        end
        def self.rm(client)
            $clients_db.where(:identifier => client.id, :address => client.client_address, :duid => client.client_duid, :type => client.client_type).delete
        end
        def self.find(client)
            $clients_db.where(:identifier => client.id, :address => client.client_address, :duid => client.client_duid, :type => client.client_type)
        end
        def self.byDBID(dbid)
            $clients_db.where(:id => dbid)
        end
    end
    class Service
        def self.new(service)
            if Database::Service.find(service) == true then
            raise TypeError
            else 
            $services_db.insert(:identifier => service.id, :address => service.service_address, :type => service.service_type)
            end
        end
        def self.rm(service)
            $services_db.where(:identifier => service.id, :address => service.service_address, :type => service.service_type).delete
        end
        def self.find(service)
            $services_db.where(:identifier => service.id, :address => service.service_address, :type => service.service_type)
        end
        def self.byDBID(dbid)
            $services_db.where(:id => dbid)
        end
    end
    class ClientService
        def self.map(service, client)
        # if does not exist
            service_id = Database::Service.find(service).get(:id)
            client_id = Database::Client.find(client).get(:id)
            $service_map_db.insert(:service_id => service_id, :client_id => client_id)
        end
        def self.rm(service, client)
            service_id = Database::Service.find(service).get(:id)
            client_id = Database::Client.find(client).get(:id)
            $service_map_db.where(:service_id => service_id, :client_id => client_id).delete 
        end
        def self.find(service,client)
            service_id = Database::Service.find(service).get(:id)
            client_id = Database::Client.find(client).get(:id)
            $service_map_db.where(:service_id => service_id, :client_id => client_id)
        end
        def self.finds(client)
            client_id = Database::Client.find(client).get(:id)
            $service_map_db.where(:client_id => client_id)
        end
        def self.findc(service)
            service_id = Database::Service.find(service).get(:id)
            $service_map_db.where(:service_id => service_id)
        end
        def self.ls()
            $service_map_db.all
        end
    end
    class ClientInstance
        def self.map(client, instance)
            # if does not exist
            client_id = Database::Client.find(client).get(:id)
            instance_id = Database::Client.find(instance).get(:id)
            $client_map_db.insert(:client_id => client_id, :instance_id => instance_id)
        end
        def self.rm(client, instance)
            client_id = Database::Client.find(client).get(:id)
            instance_id = Database::Client.find(instance).get(:id)
            $client_map_db.where(:client_id => client_id, :instance_id => instance_id).delete
        end
        def self.find(client, instance)
            client_id = Database::Client.find(client).get(:id)
            instance_id = Database::Client.find(instance).get(:id)
            $client_map_db.where(:client_id => client_id, :instance_id => instance_id)
        end
        def self.findi(client)
            client_id = Database::Client.find(client).get(:id)
            $client_map_db.where(:client_id => client_id)
        end
        def self.findc(instance)
            instance_id = Database::Client.find(instance).get(:id)
            $client_map_db.where(:instance_id => instance_id)
        end
        def self.ls()
            $client_map_db.all
        end
    end
end
