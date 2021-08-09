# frozen_string_literal: true

module Drn
  # A web application for managing mentoring services online.
  module Mentoring
    EMPTY_ARRAY = [].freeze
    EMPTY_HASH = {}.freeze

    # Load dependencies, environment variables, etc.
    require_relative 'mentoring/environment'
    init!

    # Entities
    require_relative 'mentoring/user_role'
    require_relative 'mentoring/user'
    require_relative 'mentoring/product_rate'
    require_relative 'mentoring/product'
    require_relative 'mentoring/mentoring_session'
    require_relative 'mentoring/user_registration'

    # Factory Methods
    require_relative 'mentoring/application/factories'

    # Messengers
    require_relative 'mentoring/application_messenger'

    require_relative 'mentoring/chat_service'

    # Main Application
    require_relative 'mentoring/main/products'
    require_relative 'mentoring/main/checkout'
    require_relative 'mentoring/main/mentoring_sessions'
    require_relative 'mentoring/main_helpers'
    require_relative 'mentoring/main'
  end
end
