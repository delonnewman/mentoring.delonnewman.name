# frozen_string_literal: true

$:.unshift "#{__dir__}/lib"
require_relative 'mentoring/application'

run Mentoring::Application.freeze.rack
