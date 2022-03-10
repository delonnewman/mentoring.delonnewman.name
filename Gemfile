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
# gem 'rack-routable', path: './vendor/rack-routable'
gem 'rack-flash3'
gem 'erubi'
gem 'inflection'
gem 'invokable'
# gem 'concurrent-ruby'
# gem 'nio4r'
# gem 'websocket-driver'
gem 'oj'
gem 'zeitwerk'

git 'https://github.com/delonnewman/el-toolkit.git' do
   gem 'el-core'
   gem 'el-routing'
end

# gem 'el-core', path: '../../Personal/el-toolkit/el-core'
# gem 'el-routing', path: '../../Personal/el-toolkit/el-routing'


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
