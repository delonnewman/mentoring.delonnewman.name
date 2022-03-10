# frozen_string_literal: true

module Mentoring
  module Main
    # Routes for the landing page of the site
    class Router < Application.Router()
      include Helpers
      include El::TimeUtils

      namespace '/', authenticate: false do
        get '/' do
          products = app.products.products_with_states(user: current_user, mentors: app.users.mentors_not_in_sessions)

          render :index, with: { products: products, mentor: app.users.default_mentor }
        end

        get '/state.js' do
          state = { authenticated: authenticated? }

          render js: "Mentoring = {}; Mentoring.state = #{state.to_json}"
        end
      end

      get '/dashboard' do
        render :dashboard, with: DashboardView.new(app, current_user)
      end
    end
  end
end
