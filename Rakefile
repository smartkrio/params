require './lib/outsoft.rb'
require 'rspec/core/rake_task'

namespace :db do
  desc 'Migrate the database'
  task :migrate do
    # migrations_path = lib/db/migrate
    # target_version =  ENV["VERSION"] ? ENV["VERSION"].to_i : nil
    # migrations start like bundle exec rake db:migrate VERSION=version number
    ActiveRecord::Migrator.migrate('db/migrate', ENV['VERSION'] ? ENV['VERSION'].to_i : nil)
  end

  desc 'Export params'
  task :export, [:to] do |_t, args|
    to = args[:to].to_s
    current_params = Outsoft::Param.all.to_a
    current_params = current_params.delete_if { |i| i.env_only.present? && i.env_only != to }
    ActiveRecord::Base.establish_connection(to.to_sym)
    current_params.each do |i|
      begin
        Outsoft::Param.create!(
          company_id: i.company_id,
          name: i.name,
          data: i.data,
          env_only: i.env_only
        )
      rescue Exception => e
        p "Can\'t export value, because it has excepiton #{e.message}"
      end
    end
  end

  desc 'Import params'
  task :import, [:from] do |_t, args|
    from = args[:from].to_s
    ActiveRecord::Base.establish_connection(from.to_sym)
    current_params = Outsoft::Param.all.to_a
    current_params = current_params.delete_if { |i| i.env_only.present? && i.env_only != $env }
    ActiveRecord::Base.establish_connection($env.to_sym)
    current_params.each do |i|
      begin
        Outsoft::Param.create!(
          company_id: i.company_id,
          name: i.name,
          data: i.data,
          env_only: i.env_only
        )
      rescue Exception => e
        p "Can\'t import value, because it has excepiton #{e.message}"
      end
    end
  end

  desc 'Seed'
  task :seed do
    require './db/seed.rb'
  end
end

RSpec::Core::RakeTask.new(:spec)

task default: :spec
