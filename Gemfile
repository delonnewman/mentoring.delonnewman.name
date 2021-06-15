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
gem 'rack-mini-profiler'
gem 'memory_profiler'
gem 'stackprof'

# framework stuff
gem 'dotenv'
gem 'hash_delegator'
gem 'rack-routable', path: './vendor/rack-routable'
gem 'rack-flash3'
gem 'erubi'
gem 'inflection'
gem 'concurrent-ruby'
gem 'invokable'

# vendor
gem 'stripe'
gem 'mailjet'

group :development, :test do
  gem 'rake'
  gem 'rspec'

  gem 'yard'
  gem 'webrick' # for yard documentation server

  gem 'shotgun', github: 'shotgun'
end
