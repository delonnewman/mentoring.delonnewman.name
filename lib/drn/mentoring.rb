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

    require_relative 'mentoring/application/checkout'
  end
end
