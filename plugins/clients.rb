require 'securerandom'
require 'facets/module/mattr'
require_relative '../lib/db.rb'
module Client
    @@clients = []
    attr_reader :id
    attr_reader :client_address
    attr_reader :client_duid
    attr_reader :client_type
    attr_accessor :children
    attr_accessor :state
    cattr_accessor :clients

    def self.included(klass)
        klass.extend ClassMethods
    end

    module ClassMethods
    def byAddr(client_address, client_type)
        for client in Client.clients
            if client.client_address == client_address
            if client.client_type == client_type
            return client
            end
            end
        end
        return false
    end
    def byId(id)
        for client in Client.clients
            if client.id == id
            return client
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

    def ls(client_type)
        clients = []
        for client in Client.clients
            if client.client_type == client_type
              clients << client
            end
        end
        if clients != [] 
          return clients
        else
          return "None"
        end
    end

    end

    def initialize(client_address, client_duid, client_type, *args)
        if self.class.byAddr(client_address, client_type) == false
        @old = 0
        if args.empty? 
            @id = self.class.genID()
        else
            @id = args
            @old = 1
        end

          p "old = #{@old}"
          @client_address = client_address
          @client_duid = client_duid
          @client_type = client_type
          @children = []

          Client.clients << self

          p self
          if @old == 0
              Database::Client.new(self) if $sql
          end
        else
          p "Invalid request - client already known!"
        end
    end
    
    def on()
        if @state != 1
            @state = 1
            Database::Client.find(self).update(:state => 1) if $sql
        end
    end

    def adopt(child)
       @children << child
       Database::ClientInstance.map(self, child) if $sql
    end

    def disown(child)
        @children.delete(child)
        Database::ClientInstance.rm(self, child) if $sql
    end
  
    def rm()
        Database::Client.rm(self) if $sql
        @id = nil
        @client_address = nil
        @client_duid = nil
        @client_type = nil
        @children = nil
        @state = nil
        # TODO: clean server parent ref - remove instance from service.clients
    end
end
