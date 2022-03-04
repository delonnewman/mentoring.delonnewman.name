# frozen_string_literal: true

module Mentoring
  module Products
    # Handle product interactions
    class Router < El::Router
      get '/:id/subscribe' do
        app.products.subscribe(params[:id], current_user)

        redirect_to '/dashboard'
      end
    end
  end
end
