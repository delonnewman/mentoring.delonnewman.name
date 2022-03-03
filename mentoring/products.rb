# frozen_string_literal: true

module Mentoring
  # Handle product interactions
  class Products < El::Router
    get '/:id/subscribe' do
      app.products.subscribe(params[:id], current_user)

      redirect_to '/dashboard'
    end
  end
end
