# frozen_string_literal: true

module Mentoring
  module Checkout
    # Routes for product checkout
    class Router < Application.Router()
      namespace '/checkout' do
        get '/setup', SetupController, :show
        post '/session', CheckoutSessionController, :create
        post '/customer-portal', BillingPortalController, :create
        post '/webhook', WebhookController, :create
      end

      # HACK: This should at least be a post, but it's a redirect from Stripe (see billing#checkout_success_url)
      get '/products/:id/subscribe' do
        app.products.subscribe(params[:id], current_user)

        redirect_to '/dashboard'
      end
    end
  end
end
