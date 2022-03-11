# frozen_string_literal: true

module Mentoring
  module Checkout
    # Create a checkout session
    class CheckoutSessionController < El::Controller
      def create(request)
        product = app.products.find_by!(id: request.json_body[:product_id])

        begin
          session = app.billing.create_checkout_session!(current_user, product)
          json.success(checkout_success_data(product, session))
        rescue StandardError => e
          json.error(message: e.message)
        end
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
    end
  end
end
