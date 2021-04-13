require 'bundler/setup'
Bundler.require

require 'dotenv/load'
require 'el/application'
require 'el/record'

module Drn
  # A web application for managing mentoring services online.
  module Mentoring
    require_relative 'mentoring/application'
  end
end
