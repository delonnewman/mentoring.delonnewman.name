require 'bundler/setup'
Bundler.require

require 'dry/system/container'
require 'dotenv/load'

module Drn
  # A web application for managing mentoring services online.
  module Mentoring
    require_relative 'mentoring/application'
    Import = Application.injector
  end
end
