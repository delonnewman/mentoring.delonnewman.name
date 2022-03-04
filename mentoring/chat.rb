# frozen_string_literal: true

module Mentoring
  # A resource for loading Mailjet configuration
  class Chat < Application.Resource()
    attr_reader :client

    start do
      @client = WonderLlama::Client.new(
        host: app.settings[:zulip_host],
        email: app.settings[:zulip_bot_email],
        api_key: app.settings[:zulip_api_key]
      )
    end
  end
end
