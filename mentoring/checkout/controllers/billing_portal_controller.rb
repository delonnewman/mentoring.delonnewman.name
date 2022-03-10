# frozen_string_literal: true

module Mentoring
  module Checkout
    class BillingPortalController < El::Controller
      def create(request)
        data = JSON.parse(request.body.read, symbolize_names: true)

        checkout_session = Stripe::Checkout::Session.retrieve(data[:sessionId])
        session = Stripe::BillingPortal::Session.create(
          customer: checkout_session['customer'],
          return_url: routes.root_path
        )

        render json: { url: session.url }
      end
    end
  end
end
