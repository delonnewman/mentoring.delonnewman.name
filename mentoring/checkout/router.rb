# frozen_string_literal: true

module Mentoring
  module Checkout
    # Routes for product checkout
    class Router < Application.Router()
      namespace '/checkout'

      get '/setup', CheckoutController, :setup
      post '/session', CheckoutController, :create_checkout_session
      post '/customer-portal', CheckoutController, :create_billing_portal
      post '/webhook', CheckoutController, :create_webhook
    end
  end
end
