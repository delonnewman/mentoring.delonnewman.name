source 'https://rubygems.org'

git_source :github do |repo|
  repo = "delonnewman/#{repo}" unless repo.include?('/')
  "https://github.com/#{repo}.git"
end

ruby '3.0.1'

# db
gem 'sequel'
gem "pg", "~> 1.2"

# application server
gem 'rack'
gem 'rack-contrib'
gem 'puma'

# security
gem 'bcrypt'
# gem 'rack_csrf'

# performance
gem 'rack-mini-profiler', require: false
gem 'memory_profiler'
gem 'stackprof'

# framework stuff
gem 'dotenv'
gem 'hash_delegator'
gem 'rack-flash3'
gem 'erubi'
gem 'inflection'
gem 'invokable'
# gem 'concurrent-ruby'
# gem 'nio4r'
# gem 'websocket-driver'
gem 'oj'
gem 'zeitwerk'

# path '../../Personal/el-toolkit/el-core' do
git 'https://github.com/delonnewman/el-toolkit.git' do
   gem 'el-core', require: 'el/core_ext/all'
   gem 'el-routing', require: 'el/routable'
end

# vendor
gem 'stripe'
gem 'mailjet'
gem 'wonder-llama', require: 'wonder_llama', github: 'delonnewman/wonder-llama' # Zulip Chat
gem 'zoom_rb'
gem 'honeybadger', "~> 4.0"
gem 'net-ntp', require: 'net/ntp'
gem 'timezone'

group :development, :test do
  gem 'rake'
  gem 'rspec'
  gem 'rubocop'
  gem 'capybara'
  gem 'cucumber'
  gem 'faker'

  gem 'filewatcher'

  gem 'yard'
  gem 'webrick' # for yard documentation server
  gem 'rack-livereload'
end
