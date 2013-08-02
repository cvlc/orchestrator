#!/usr/bin/env ruby
require 'parseconfig'

$config = ParseConfig.new('./settings.cfg')
$secret = $config['orchestrator']['shared_secret']