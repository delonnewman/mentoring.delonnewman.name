# frozen_string_literal: true

module Drn
  # A web application for managing mentoring services online.
  module Mentoring
    EMPTY_ARRAY = [].freeze
    EMPTY_HASH = {}.freeze

    # Load dependencies, environment variables, etc.
    require_relative 'mentoring/environment'
  end
end
