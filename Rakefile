task :default => :spec

desc "Run spec"
task :spec do
  sh "source .env && bundle exec rspec"
end

desc "Open project console"
task :console do
  sh "irb -r ./lib/drn/mentoring.rb"
end

desc "Run development server"
task :server do
  sh "bundle exec shotgun"
end

desc "Setup application"
task :setup => :'db:migrate'

namespace :db do
  desc "Run migrations"
  task :migrate do
    sh "source .env && bundle exec sequel $DATABASE_URL -m db/migrations/"
  end
end

namespace :gem do
  desc "Run documentation server for bundled gems"
  task :server do
    sh "bundle exec yard server -g"
  end

  desc "Generate documentation for bundled gems"
  task :docs do
    sh "bundle exec gem rdoc --all"
  end
end

namespace :assets do

end
