# frozen_string_literal: true

module Mentoring
  module Checkout
    # A controller for handling checkout logic
    class CheckoutController < El::Controller
      def setup
        render json: setup_data
      end

      def setup_data
        {
          pub_key: app.settings[:stripe_pub_key],
          prices: app.products.project(:name, :price_id, id: :product_id)
        }
      end

      # rubocop:disable Metrics/AbcSize
      def create_checkout_session(request)
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

      def create_billing_portal(request)
        data = JSON.parse(request.body.read, symbolize_names: true)

        checkout_session = Stripe::Checkout::Session.retrieve(data[:sessionId])
        session = Stripe::BillingPortal::Session.create(
          customer: checkout_session['customer'],
          return_url: routes.root_path
        )

        render json: { url: session.url }
      end

      def create_webhook(request)
        begin
          construct_stripe_event(request)
        rescue Stripe::SignatureVerificationError, JSON::ParserError => e
          render json: { status: 'error', message: e.message }, status: 400
        end

        if event['type'] == 'checkout.session.completed'
          render json: { status: 'success' }
        else
          render json: { status: 'error', data: event }
        end
      end

      def construct_stripe_event(request)
        webhook_secret = app.settings[:strip_webhook_secret]

        if !webhook_secret.empty?
          sig_header = request['HTTP_STRIPE_SIGNATURE']
          Stripe::Webhook.construct_event(request.body.read, sig_header, webhook_secret)
        else
          Stripe::Event.construct_from(request.json_body)
        end
      end
    end
  end
end
