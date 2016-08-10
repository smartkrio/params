$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'outsoft.rb'
require 'rspec/its'
require 'database_cleaner'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end
end
