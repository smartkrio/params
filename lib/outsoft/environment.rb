$env = (ENV['OUTSOFT_ENV']|| :development).to_sym

db_path = File.join(File.dirname(__FILE__), '../', 'config', 'database.yml')
$db_config = YAML::load(File.open(db_path))

raise "Undefined #{env} settings for database in #{db_path}" unless $db_config[$env.to_s].present?

# Base settings for ActiveRecord
ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.configurations = $db_config
ActiveRecord::Base.establish_connection($env)
ActiveRecord::Base.logger = nil
