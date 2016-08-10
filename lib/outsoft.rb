lib = File.expand_path('..', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rubygems'
require 'active_record'
require 'yaml'
require 'date'
require 'outsoft/params_validator.rb'
require 'outsoft/clients_validator.rb'
require 'outsoft/param.rb'
require 'outsoft/params.rb'
require 'outsoft/client.rb'
require 'outsoft/clients.rb'
require 'outsoft/environment.rb'
