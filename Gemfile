source 'https://rubygems.org'

git_source :github do |repo|
  repo = "delonnewman/#{repo}" unless repo.include?('/')
  "https://github.com/#{repo}.git"
end

ruby '3.0.1'

# db
gem 'pg'
gem 'sequel'

# application server
gem 'rack'
gem 'rack-contrib'
gem 'puma'

# security
gem 'bcrypt'
gem 'rack_csrf'

# performance
# gem 'rack-mini-profiler'
# gem 'memory_profiler'
# gem 'stackprof'

# framework stuff
gem 'dotenv'
gem 'hash_delegator'
gem 'rack-routable', path: './vendor/rack-routable'
gem 'rack-flash3'
gem 'erubi'
gem 'inflection'
gem 'concurrent-ruby'
gem 'invokable'
gem 'nio4r'
gem 'websocket-driver'
gem 'oj'

# vendor
gem 'stripe'
gem 'mailjet'
gem 'wonder-llama', require: 'wonder_llama', github: 'delonnewman/wonder-llama' # Zulip Chat
gem 'zoom_rb'

group :development, :test do
  gem 'rake'
  gem 'rspec'
  gem 'prettier'
  gem 'rubocop'
  gem 'capybara'
  gem 'cucumber'
  gem 'faker'

  gem 'pry'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'

  gem 'yard'
  gem 'webrick' # for yard documentation server

  gem 'shotgun', github: 'shotgun'
end
