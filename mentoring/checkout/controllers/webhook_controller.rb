# frozen_string_literal: true

module Mentoring
  module Checkout
    class WebhookController < El::Controller
      def create(request)
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
        webhook_secret = app.settings[:stripe_webhook_secret]

        if !webhook_secret.empty?
          sig_header = request[:http_stripe_signature]
          Stripe::Webhook.construct_event(request.body.read, sig_header, webhook_secret)
        else
          Stripe::Event.construct_from(request.json_body)
        end
      end
    end
  end
end
