# frozen_string_literal: true

module Mentoring
  module Checkout
    class WebhookController < ApplicationController
      def create
        begin
          construct_stripe_event(request)
        rescue Stripe::SignatureVerificationError, JSON::ParserError => e
          json.error(e.message, status: 400)
        end

        if event['type'] == 'checkout.session.completed'
          json.success
        else
          json.error(event, status: 400)
        end
      end

      private

      def construct_stripe_event(request)
        webhook_secret = app.settings[:stripe_webhook_secret]

        if !webhook_secret.empty?
          sig_header = request[:http_stripe_signature]
          Stripe::Webhook.construct_event(request.body.read, sig_header, webhook_secret)
        else
          Stripe::Event.construct_from(request.json)
        end
      end
    end
  end
end
