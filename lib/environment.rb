require 'parseconfig'

$config = ParseConfig.new('./settings.cfg')

if $config['sql']['enabled'] == 'true'
  require 'sequel'
  if $config['sql']['connection_string']
    DB = Sequel.connect($config['sql']['connection_string'])
  else
    DB = Sequel.sqlite
  end
end

$secret = $config['orchestrator']['shared_secret']
