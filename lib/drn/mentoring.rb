# frozen_string_literal: true
require 'pp'
require 'cgi'
require 'set'
require 'json'
require 'logger'
require 'pathname'
require 'forwardable'

require 'bundler/setup'
Bundler.require
Dotenv.load

module Drn
  # A web application for managing mentoring services online.
  module Mentoring
    # Simple utility methods
    require_relative 'mentoring/utils'

    # Application state
    require_relative 'mentoring/application'
    App = Application.new.init!

    # Entities
    require_relative 'mentoring/entity'
    require_relative 'mentoring/product'
    require_relative 'mentoring/session'
    require_relative 'mentoring/user'

    # Repositories
    require_relative 'mentoring/repository'
    require_relative 'mentoring/product_repository'
    require_relative 'mentoring/session_repository'
    require_relative 'mentoring/user_repository'

    # Factory Methods
    require_relative 'mentoring/application/factories'

    # Simple utility methods for controller / view code
    require_relative 'mentoring/application/helpers'

    # Controllers
    require_relative 'mentoring/controller'
    require_relative 'mentoring/application/checkout'
    require_relative 'mentoring/application/instant_sessions'
    require_relative 'mentoring/application/main'
  end
end
