# frozen_string_literal: true

module Mentoring
  module Checkout
    # Routes for product checkout
    class Router < Application.Router()
      namespace '/checkout'

      get '/setup', SetupController, :show
      post '/session', CheckoutSessionController, :create
      post '/customer-portal', BillingPortalController, :create
      post '/webhook', WebhookController, :create
    end
  end
end
