# frozen_string_literal: true

module Mentoring
  module Checkout
    # A controller for handling checkout logic
    class SetupController < ApplicationController
      def show
        render json: setup_data
      end

      def setup_data
        {
          pub_key: app.settings[:stripe_pub_key],
          prices: app.products.project(:name, :price_id, id: :product_id)
        }
      end
    end
  end
end
