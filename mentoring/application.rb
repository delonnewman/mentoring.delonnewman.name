# frozen_string_literal: true

require_relative '../lib/drn/framework'

# A mentoring website (see https://mentoring.delonnewman.name)
module Mentoring
  # Represents the application state
  class Application < Drn::Framework::Application::Base
    include Drn::Framework::Application::Authenticable

    find_user do |user_id|
      users.find_by!(id: user_id)
    end

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

    entities :user, :product, :mentoring_session, :user_registration, :product_rate, :user_role
    resources :database, :mailjet, :stripe, :zoom, :zulip, :profiler
    packages :billing
    routers :main, :checkout, :mentoring_sessions, :products

    def messenger
      @messenger ||= ApplicationMessenger.new(self)
    end

    def default_mentor
      @default_mentor ||= users.find_by!(username: settings[:default_mentor_username])
    end

    # TODO: remove this
    def call(env)
      env['mentoring.app'] = self

      super
    end
  end
end
