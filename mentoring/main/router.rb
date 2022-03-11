# frozen_string_literal: true

module Mentoring
  module Main
    # Routes for the landing page of the site
    class Router < Application.Router()
      include Helpers

      namespace '/', authenticate: false do
        get '/', Controller, :index
        get '/state.js', Controller, :state
      end

      get '/dashboard', Controller, :dashboard
    end
  end
end
