require 'pp'
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
    M = Application.new.init!
  end
end
