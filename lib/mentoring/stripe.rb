# frozen_string_literal: true

module Mentoring
  # Load configuration for Stripe integration
  class Stripe
    include Drn::Framework::Application::Resource

    def load
      ::Stripe.api_key = app.settings[:stripe_key]
    end
  end
end
