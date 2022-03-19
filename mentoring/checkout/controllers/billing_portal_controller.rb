# frozen_string_literal: true

module Mentoring
  module Checkout
    # Create a billing portal
    class BillingPortalController < ApplicationController
      def create
        checkout_session = Stripe::Checkout::Session.retrieve(params[:sessionId])
        session = Stripe::BillingPortal::Session.create(
          customer: checkout_session['customer'],
          return_url: routes.root_path
        )

        json url: session.url
      end
    end
  end
end
