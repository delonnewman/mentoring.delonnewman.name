# frozen_string_literal: true

module Mentoring
  module Checkout
    # Create a checkout session
    class CheckoutSessionController < ApplicationController
      def create
        product = app.products.find_by!(id: params.fetch(:product_id))
        session = app.billing.create_checkout_session!(
          current_user,
          product,
          success_url: checkout_success_url(product),
          cancel_url: routes.root_url
        )

        json.success(checkout_success_data(product, session))
      end

      def subscribe
        app.products.subscribe(params[:id], current_user)

        redirect_to routes.dashboard_path
      end

      private

      def checkout_success_data(product, session)
        if product.subscription?
          { type: 'complete', sessionId: session.id }
        else
          {
            type: 'setup',
            sessionId: session.id,
            setupIntent: session.setup_intent
          }
        end
      end

      def checkout_success_url(product)
        if product.subscription?
          "#{routes.products_subscribe_url(product.id)}?session_id={CHECKOUT_SESSION_ID}"
        else
          "#{routes.session_new_url(product_id: product.id)}&session_id={CHECKOUT_SESSION_ID}"
        end
      end
    end
  end
end
