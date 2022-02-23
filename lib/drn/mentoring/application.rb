# frozen_string_literal: true

require 'rack/contrib/try_static'

require_relative 'application/database'
require_relative 'application/mailjet'
require_relative 'application/stripe'
require_relative 'application/zoom'
require_relative 'application/zulip'
require_relative 'application/profiler'

require_relative 'billing'

module Drn
  # A mentoring website (see https://mentoring.delonnewman.name)
  module Mentoring
    # Represents the application state
    class Application < Framework::Application::Base
      from_env :database_url,
               :domain,
               :stripe_key,
               :strip_pub_key,
               :mentoring_session_secret,
               :mailjet_api_key,
               :mailjet_secret_key,
               :zulip_host,
               :zulip_bot_email,
               :zulip_api_key,
               :zoom_api_key,
               :zoom_api_secret,
               :default_mentor_username

      resource Database
      resource Mailjet
      resource Stripe
      resource Zoom
      resource Zulip
      resource Profiler

      package Billing
    end
  end
end
