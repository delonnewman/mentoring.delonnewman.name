# frozen_string_literal: true

module Mentoring
  module Main
    # Routes for the landing page of the site
    class Router < Application.Router()
      def error(err)
        app.logger.error(err.message)
        app.logger.error(err.backtrace)

        [500, {}, ['Server Error']]
      end

      namespace '/', authenticate: false do
        get '/', MentorController, :index
        get '/state.js', MentorController, :state, as: :client_state
      end

      get '/dashboard', DashboardController, :index, authenticate: true
    end
  end
end
