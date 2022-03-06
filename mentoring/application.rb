# frozen_string_literal: true

require_relative '../lib/el'

# A mentoring website (see https://mentoring.delonnewman.name)
module Mentoring
  # Represents the application state
  class Application < El::Application::Base
    include El::Authenticable

    find_user do |user_id|
      users.find_by!(id: user_id)
    end

    env_vars :database_url,
             :database_name,
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
  end
end
