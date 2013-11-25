require 'sequel'
require 'json'
require 'net/http'

$docker_db = DB[:docker]
$dockerc_map_db = DB[:dockerc_map]

if $config['sql']['init'] == "true"
    DB.create_table! :docker do
        primary_key :id
        String :longid
        String :image
        String :command
        String :created
        String :status
        String :ports
    end
    DB.create_table! :dockerc_map do
        primary_key :id
        String :instance_id
        String :container_id
    end
else
# TODO: For future container persistence, we'd need to load up working memory with the tables.
# DB[:docker].each{ |d| container = nil; Docker::Container.all(:all => true).each do |c|; container = c if d.longid == c["ID"].to_s; end; Client::Docker.new(container["address"],container["duid"],"Docker") }
# DB[:dockerc_map].each{ |m| dockerdb = Database::Docker.byDBID(m[:instance_id]); instancedb = Database::Docker.byDBID(m[:container_id]); client = Client::Generic.byId(instancedb[:identifier]); instance = Client::Docker.byId(dockerdb[:identifier]); client.dadopt(instance,1) }
end

class Database::Docker
include Database
        def self.add(client)
            if Database::Docker.find(client) == true then
            raise TypeError 
            else
            container = client.json
            # TODO: Firewall eth1 too, so we only allow traffic over certain ports or/and to certain hosts
            #ports = container["NetworkSettings"]["PortMapping"]["Tcp"].to_s << container["NetworkSettings"]["PortMapping"]["Udp"].to_s
            ports = "0"
            $docker_db.insert(:longid => container["ID"].to_s, :image => container["Config"]["Image"].to_s, :command => container["Config"]["Cmd"].to_s, :created => container["Created"].to_s, :status => container["State"]["Running"].to_s, :ports => ports)
            end
        end
        def self.rm(client)
            container = client.json
            $docker_db.where(:longid => container["ID"].to_s, :image => container["Config"]["Image"].to_s).delete
        end
        def self.find(client)
            container = client.json
            $docker_db.where(:longid => container["ID"].to_s, :image => container["Config"]["Image"].to_s)
        end
        def self.byDBID(dbid)
            $docker_db.where(:id => dbid)
        end
end

class Database::DockerCMap
include Database
        def self.map(instance, container)
            # if does not exist
            instance_id = Database::Client.find(instance).get(:id)
            container_id = Database::Docker.find(container).get(:id)
            $dockerc_map_db.insert(:instance_id => instance_id, :container_id => container_id)
        end
        def self.rm(instance, container)
            instance_id = Database::Client.find(instance).get(:id)
            container_id = Database::Docker.find(container).get(:id)
            $dockerc_map_db.where(:instance_id => instance_id, :container_id => container_id).delete
        end
        def self.find(instance, container)
            instance_id = Database::Client.find(instance).get(:id)
            container_id = Database::Docker.find(container).get(:id)
            $dockerc_map_db.where(:instance_id => instance_id, :container_id => container_id)
        end
        def self.findc(instance)
            instance_id = Database::Client.find(instance).get(:id)
            $dockerc_map_db.where(:instance_id => instance_id)
        end
        def self.findi(container)
            container_id = Database::Docker.find(container).get(:id)
            $dockerc_map_db.where(:container_id => container_id)
        end
        def self.ls()
            $dockerc_map_db.all
        end
end
