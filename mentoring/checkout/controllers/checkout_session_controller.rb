# frozen_string_literal: true

module Mentoring
  module Checkout
    class CheckoutSessionController < El::Controller
      # rubocop:disable Metrics/AbcSize
      def create(request)
        product = app.products.find_by!(id: request.json_body[:product_id])

        begin
          session = app.billing.create_checkout_session!(current_user, product)
          render json: app.billing.checkout_success_data(product, session)
        rescue StandardError => e
          logger.error e
          render json: { status: 'error', message: e.message }, status: 400
        end
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
