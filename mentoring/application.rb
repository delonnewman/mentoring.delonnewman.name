# frozen_string_literal: true

require_relative '../lib/el'
require 'rack-mini-profiler'

# A mentoring website (see https://mentoring.delonnewman.name)
module Mentoring
  # Represents the application state
  class Application < El::Application::Base
    include El::Authenticable

    use Rack::MiniProfiler
    use Honeybadger::Rack::ErrorNotifier

    env_vars :database_url,
             :database_name,
             :domain,
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
             :default_mentor_username
  end
end
