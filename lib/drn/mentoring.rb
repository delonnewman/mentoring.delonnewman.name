# frozen_string_literal: true
require 'pp'
require 'set'
require 'json'
require 'logger'
require 'pathname'

require 'bundler/setup'
Bundler.require
Dotenv.load

module Drn
  # A web application for managing mentoring services online.
  module Mentoring
    # Application state
    require_relative 'mentoring/application'
    App = Application.new.init!

    # Controllers
    require_relative 'mentoring/controller'
    require_relative 'mentoring/application/checkout'

    # Factory Methods
    require_relative 'mentoring/application/factories'

    # Entities
    require_relative 'mentoring/entity'
    require_relative 'mentoring/product'

    # Repositories
    require_relative 'mentoring/repository'
    require_relative 'mentoring/product_repository'
  end
end
