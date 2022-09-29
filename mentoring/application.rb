# frozen_string_literal: true

require 'mentoring'
require 'rack-mini-profiler'

# A mentoring website (see https://mentoring.delonnewman.name)
module Mentoring
  # Represents the application state
  class Application < El::Application::Base
    use Rack::MiniProfiler
    use Honeybadger::Rack::ErrorNotifier

    plugin El::Authenticable

    disable :livereload

    env_vars :database_url,
             :database_name, # FIXME: parse database url for this
             :domain, # FIXME: I don't think we need this
             # FIXME: these would be better in named yaml or ini config files
             :stripe_key,
             :stripe_pub_key,
             :session_secret,
             :mailjet_api_key,
             :mailjet_secret_key,
             :zulip_host,
             :zulip_bot_email,
             :zulip_api_key,
             :zoom_api_key,
             :zoom_api_secret,
             :default_mentor_username # FIXME: this would probably be better in a user config file
  end
end
