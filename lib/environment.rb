require 'parseconfig'

$config = ParseConfig.new('./settings.cfg')

if $config['sql']['connection_string'] then
DB = Sequel.connect($config['sql']['connection_string'])
else
DB = Sequel.sqlite
end

$secret = $config['orchestrator']['shared_secret']
