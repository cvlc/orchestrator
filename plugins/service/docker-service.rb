require 'docker'
require_relative '../services'

#Docker.url = "http://127.0.0.1"
#Docker.options = { :port => 4243 }
#Docker.validate_version!

class Service::Docker
include Service
end
