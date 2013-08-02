require 'securerandom'
require 'facets/module/mattr'
require_relative '../lib/db.rb'
module Service 
    @@services = []
    attr_reader :id
    attr_reader :service_address
    attr_reader :service_type
    cattr_accessor :services

    def self.included(klass)
        klass.extend ClassMethods
    end

    module ClassMethods
    def byAddr(service_address, service_type)
        for server in Service.services
            if server.service_address == service_address
              if server.service_type == service_type
              return server
              end
            end
        end
        return false
    end

    def byId(service_id)
        for server in Service.services
            if server.id == service_id
            return server
            end
        end
        return true
    end

    def genID()
        id = SecureRandom.hex 
        if self.byId(id) == true
          id = SecureRandom.hex 
          return id 
        end
    end


    def ls(service_type)
        services = []
        for server in Service.services
            if server.service_type == service_type
            services << server
            end
        end
        if services != []
        return services
        else
        return "None"
        end
    end
    end

    def initialize(service_address, service_type, *args)
      if self.class.byAddr(service_address, service_type) == false
        @clients = []
        @old = 0
        if args.empty?
            @id = self.class.genID()
        else
            @old = 1
            @id = args
        end
        p "old = #{@old}"
        @service_address = service_address
        @service_type = service_type
        Service.services << self

        p self
        if @old == 0
            Database::Service.new(self)
        end
      else 
       p "Invalid request - server already known!"
      end
    end

    def rm()
        Database::ClientService.findc(self).delete
        Database::Service.rm(self)
        @clients = nil
        @service_type = nil
        @service_address = nil
        @id = nil
    end

    def addclient(client)
            Database::ClientService.map(self, client)
            @clients << client
    end

    def rmclient(client)
            Database::ClientService.rm(self, client)
            @clients.delete(client)
    end
end
