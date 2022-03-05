require_relative 'mentoring/application'

App = Mentoring::Application.new(:development).tap do |app|
  app.settings.load!
end

task default: :spec

TEST_ENV = App.ci? ? 'ci' : 'test'

desc 'Run spec'
task :spec do
  sh "RACK_ENV=#{TEST_ENV} bundle exec rspec"
end

desc 'Open project console'
task :console do
  sh 'bundle exec irb -Ilib -r./.console.rb'
end

desc 'Run development server'
task :server do
  sh 'bundle exec shotgun -o 0.0.0.0 -p 3000'
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
    sh "bundle exec sequel '#{ENV['DATABASE_URL']}' -m db/migrations/"
  end

  desc 'Drop tables'
  task :drop_tables do
    sh "source .env && bundle exec sequel '#{ENV['DATABASE_URL']}' -c 'DB.tables.each { |t| DB.drop_table?(t, cascade: true) }'"
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

  desc 'Compile assets for deployment'
  task compile: %w[./public/js/chat.js]

  file './public/js/chat.js' do
    if App.production?
      sh 'npx esbuild apps/chat/client.js --bundle --minify --target=chrome58,firefox57,safari11,edge16 --outfile=./public/js/chat.js'
    else
      sh 'npx esbuild apps/chat/client.js --bundle --minify --sourcemap --target=chrome58,firefox57,safari11,edge16 --outfile=./public/js/chat.js'
    end
  end
end
