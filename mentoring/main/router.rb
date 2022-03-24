# frozen_string_literal: true

module Mentoring
  module Main
    # Routes for the landing page of the site
    class Router < Application.Router()
      include Helpers

      namespace '/', authenticate: false do
        get '/', MentorController, :index
        get '/state.js', MentorController, :state
      end

      get '/dashboard', DashboardController, :index
    end
  end
end
