desc "Open project console"
task :console do
  sh "irb -r ./lib/drn/mentoring.rb"
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
