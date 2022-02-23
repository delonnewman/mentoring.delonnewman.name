# frozen_string_literal: true

module Drn
  # A mentoring website (see https://mentoring.delonnewman.name)
  module Mentoring
    # Represents the application state
    class Application < Framework::Application::Base
      env_vars :database_url,
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

      entities :user, :product, :mentoring_session, :user_registration
      resources :database, :mailjet, :stripe, :zoom, :zulip, :profiler
      packages :billing
      routers :main
    end
  end
end
