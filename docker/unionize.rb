#!/usr/bin/env ruby
require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'sinatra/json'
require 'docker'
require './lib/environment'
require './lib/unionize-methods'

CERT_PATH = $config['cert']['path']
Docker.url = $config['docker']['url']
Docker.options = { :port => $config['docker']['port'] }
Docker.validate_version!

webrick_options = {
    :BindAddress    =>      $config['web']['address'],
    :Port           =>      $config['web']['port'],
    :Logger         =>      WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
    :DocumentRoot   =>      './public',
    :SSLEnable      =>      true,
    :SSLVerifyClient    =>  OpenSSL::SSL::VERIFY_NONE,
    :SSLCertificate =>      OpenSSL::X509::Certificate.new(File.open(File.join(CERT_PATH, $config['cert']['cert'])).read),
    :SSLPrivateKey  =>      OpenSSL::PKey::RSA.new(File.open(File.join(CERT_PATH, $config['cert']['key'])).read),
    :SSLCertName    =>  [ [ "CN",WEBrick::Utils::getservername ]
    ]
}

class DockerHelper < Sinatra::Base
    post '/container' do
    container_id = params[:container_id]
    secret_recv = params[:secret]
    container_address = unionize(container_id,secret_recv)
    p "Ending"
    "#{container_address}" || "Exists"
    end
end

Rack::Handler::WEBrick.run DockerHelper, webrick_options
