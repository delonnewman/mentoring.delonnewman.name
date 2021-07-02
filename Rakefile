require_relative 'lib/drn/mentoring/environment'
Drn::Mentoring.app.load_env!

task default: :spec

desc 'Run spec'
task :spec do
  sh 'RACK_ENV=test bundle exec rspec --no-color'
end

desc 'Open project console'
task :console do
  sh 'irb -Ilib -rdrn/mentoring/console'
end

desc 'Run development server'
task :server do
  sh 'bundle exec shotgun -p 3000'
end

desc 'Make Source Code Prettier'
task :pretty do
  sh 'bundle exec rbprettier --write "{lib,db,assets,scripts,spec,templates}/**/*.{rb,js,html,css,scss}"'
end

namespace :db do
  desc 'Setup database (i.e. create, migrate and seed)'
  task setup: [:'db:create', :'db:migrate', :'db:seed']

  desc 'Seed Database'
  task :seed do
    sh './scripts/init-data'
  end

  desc 'Run migrations'
  task :migrate do
    sh "bundle exec sequel #{ENV['DATABASE_URL']} -m db/migrations/"
  end

  desc 'Drop tables'
  task :drop_tables do
    sh "source .env && bundle exec sequel #{ENV['DATABASE_URL']} -c 'DB.tables.each { |t| DB.drop_table?(t, cascade: true) }'"
  end

  desc 'Drop database'
  task :drop do
    sh "psql -c 'DROP DATABASE #{ENV['DATABASE_NAME']}'"
  end

  desc 'Open database console'
  task :console do
    sh "psql #{ENV['DATABASE_NAME']}"
  end

  desc 'Create database'
  task :create do
    sh "createdb #{ENV['DATABASE_NAME']}"
  end

  desc 'Dump schema do db/schema.sql'
  task :dump do
    sh "bundle exec sequel #{ENV['DATABASE_URL']} --dump-schema db/schema.sql"
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
