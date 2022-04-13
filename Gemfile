source 'https://rubygems.org'

ruby '3.0.4'

# db
gem 'sequel'
gem "pg", "~> 1.2"

# application server
gem 'rack'
gem "falcon", "~> 0.39.2"
gem "puma", "~> 5.6.2"

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
gem 'concurrent-ruby'
gem 'nio4r'
# gem 'websocket-driver'
gem 'oj'
gem 'zeitwerk'
gem 'rake'

# path '../../Personal/el-toolkit' do
git 'https://github.com/delonnewman/el-toolkit.git' do
   gem 'el-core', require: 'el/core_ext/all'
   gem 'el-routing', require: false
   gem 'el-modeling', require: false
   gem 'el-application', require: 'el/application'
end

# vendor
gem 'stripe'
gem 'mailjet'
gem 'wonder-llama', require: 'wonder_llama', github: 'delonnewman/wonder-llama' # Zulip Chat
gem 'zoom_rb'
gem 'honeybadger', "~> 4.0"
gem 'net-ntp', require: 'net/ntp'
gem 'timezone'

group :development do
  gem 'filewatcher'

  gem 'yard'
  gem 'webrick' # for yard documentation server
  gem 'rack-livereload', require: false

  gem 'rubocop'
end

group :development, :test do
  gem 'minitest'
  gem 'minitest-autotest'

  gem 'capybara'
  gem 'cucumber'
  gem 'faker'
end
