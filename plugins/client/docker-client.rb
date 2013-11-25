require 'docker'
require 'json'
require 'net/http'
require_relative '../clients'
require_relative './docker-client-db.rb' if $sql 

Docker.url = $config['docker']['url']
Docker.options = { :port => $config['docker']['port'] }
Docker.validate_version!

class Client::Docker
include Client
    attr_accessor :containers
    @containers = []
    def self.provision()
       container = ::Docker::Container.create('Cmd' => [$config['docker']['command']], 'Image' => $config['docker']['image'])
       container.start()
       http = Net::HTTP.new($config['docker']['helper_address'],$config['docker']['helper_port']); http.use_ssl = true; http.verify_mode = OpenSSL::SSL::VERIFY_NONE
       http.read_timeout = 300
       container_id = container.json["ID"].to_s
       request = Net::HTTP::Post.new("/container")
       request.set_form_data({ "container_id" => container_id, "secret" => $secret })
       response = http.request(request)
       Database::Docker.add(container) if $sql
       return response.body()
    end

    def self.deprovision()
        container.kill()
        Database::Docker.rm(container) if $sql
        return true
    end

    def dadopt(docker_container, *args)
        @containers << docker_container
        if args == 1
        return
        else
        Database::DockerCMap.map(self,docker_container) if $sql
        end
    end
    def ddisown(docker_container)
        @containers.delete(docker_container)
        Database::DockerCMap.rm(self,docker_container) if $sql
    end
    def dls(docker_container)
        return @containers
    end
end
