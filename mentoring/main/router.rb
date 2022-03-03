# frozen_string_literal: true

module Mentoring
  module Main
    # Routes for the landing page of the site
    class Router < El::Router
      include Helpers
      include El::TimeUtils

      static '/' => 'public'

      get '/', authenticate: false do
        products = app.products.products_with_states(user: current_user, mentors: app.users.mentors_not_in_sessions)

        render :index, with: {
          products: products,
          mentor: app.default_mentor
        }
      end

      get '/dashboard' do
        render :dashboard, with: Dashboard.new(app, current_user)
      end

      get '/state.js', authenticate: false do
        state = { authenticated: app.authenticated? }

        render js: "Mentoring = {}; Mentoring.state = #{state.to_json}"
      end

      def error(error)
        logger.error error.message
        error.backtrace.each { |trace| logger.error "  #{trace}" }

        render :error
      end
    end
  end
end
