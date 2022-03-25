require_relative 'mentoring/application'
App = Mentoring::Application.with_only_settings

desc 'Open project console'
task :console do
  sh 'bundle exec pry -Ilib -r./.console.rb'
end

desc 'Run development server'
task :server do
  sh 'bundle exec puma -b tcp://0.0.0.0 -p 3000'
end

namespace :db do
  desc 'Setup database (i.e. create, migrate and seed)'
  task setup: %i[db:create db:migrate db:seed]

  desc 'Seed Database'
  task :seed do
    sh './scripts/init-data'
  end

  desc 'Run migrations'
  task :migrate do
    sh "bundle exec sequel '#{App.settings[:database_url]}' -m db/migrations/"
  end

  desc 'Drop tables'
  task :drop_tables do
    sh "bundle exec sequel '#{App.settings[:database_url]}' -c 'DB.tables.each { |t| DB.drop_table?(t, cascade: true) }'"
  end

  desc 'Drop database'
  task :drop do
    sh "psql -c 'DROP DATABASE #{App.settings[:database_name]}'"
  end

  desc 'Open database console'
  task :console do
    sh "psql #{App.settings[:database_name]}"
  end

  desc 'Create database'
  task :create do
    sh "createdb #{App.settings[:database_name]}"
  end

  desc 'Dump schema do db/schema.sql'
  task :dump do
    sh "bundle exec sequel #{App.settings[:database_url]} --dump-schema db/schema.sql"
  end
end

namespace :gem do
  desc 'Run documentation server for bundled gems'
  task :server do
    sh 'bundle exec yard server -g'
  end

  desc 'Generate documentation for bundled gems'
  task :docs do
    sh 'bundle exec gem rdoc --all'
  end
end

namespace :assets do
  desc 'Pull asset dependencies'
  task :deps do
    sh 'npm install'
  end
end
