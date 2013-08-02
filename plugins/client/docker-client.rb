require 'docker'
require 'json'
require 'net/http'
require_relative '../clients'

$docker_db = DB[:docker]
$dockerc_map_db = DB[:dockerc_map]

Docker.url = $config['docker']['url']
Docker.options = { :port => $config['docker']['port'] }
Docker.validate_version!

if $create_db
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
#    DB[:docker].each{ |d| }
#    DB[:dockerc_map].each{ |m| dockerdb = Database::Docker.byDBID(m[:instance_id]); instancedb = Database::Docker.byDBID(m[:container_id]); client = Client::Generic.byId(instancedb[:identifier]); instance = Client::Docker.byId(dockerdb[:identifier]); client.dadopt(instance,1)  }
end

class Client::Docker
include Client
    attr_accessor :containers
    @containers = []
    def self.provision()
       container = ::Docker::Container.create('Cmd' => [$config['docker']['command']], 'Image' => $config['docker']['image'])
       container.start()
       http = Net::HTTP.new($config['docker']['helper_address'],$config['docker']['helper_port']); http.use_ssl = true; http.verify_mode = OpenSSL::SSL::VERIFY_NONE
       container_id = container.json["ID"].to_s
       request = Net::HTTP::Post.new("/container")
       request.set_form_data({ "container_id" => container_id, "secret" => $secret })
       response = http.request(request)
       Database::Docker.add(container)
       return response.body()
    end

    def self.deprovision()
        container.kill()
        Database::Docker.rm(container) 
        return true
    end

    def dadopt(docker_container, *args)
        @containers << docker_container
        if args == 1
        return
        else
        Database::DockerCMap.map(self,docker_container)
        end
    end
    def ddisown(docker_container)
        @containers.delete(docker_container)
        Database::DockerCMap.rm(self,docker_container)
    end
    def dls(docker_container)
        return @containers
    end
end

class Database::Docker
include Database
        def self.add(client)
            if Database::Docker.find(client) == true then
            raise TypeError 
            else
            container = client.json
            ports = container["NetworkSettings"]["PortMapping"]["Tcp"].to_s << container["NetworkSettings"]["PortMapping"]["Udp"].to_s
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
