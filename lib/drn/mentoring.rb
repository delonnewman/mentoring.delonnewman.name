# frozen_string_literal: true

module Drn
  # A web application for managing mentoring services online.
  module Mentoring
    EMPTY_ARRAY = [].freeze
    EMPTY_HASH  = {}.freeze

    # Load dependencies, environment variables, etc.
    require_relative 'mentoring/environment'
    init!

    # Templating
    require_relative 'mentoring/templated'
    require_relative 'mentoring/template_helpers'
    require_relative 'mentoring/template'
    
    # Repositories
    require_relative 'mentoring/repository'
    require_relative 'mentoring/product_repository'
    require_relative 'mentoring/mentoring_session_repository'
    require_relative 'mentoring/user_repository'

    # Entities
    require_relative 'mentoring/entity'
    require_relative 'mentoring/user_role'
    require_relative 'mentoring/user'
    require_relative 'mentoring/product_rate'
    require_relative 'mentoring/product'
    require_relative 'mentoring/mentoring_session_status'
    require_relative 'mentoring/mentoring_session'
    require_relative 'mentoring/user_registration'

    # Factory Methods
    require_relative 'mentoring/application/factories'

    # Simple utility methods for controller / view code
    require_relative 'mentoring/application/helpers'

    # Controllers
    require_relative 'mentoring/controller'
    require_relative 'mentoring/application/authenticated_controller'
    require_relative 'mentoring/application/checkout'
    require_relative 'mentoring/application/mentoring_sessions'
    require_relative 'mentoring/application/users'
    require_relative 'mentoring/application/main'

    # Mailers
    require_relative 'mentoring/mailer'
    require_relative 'mentoring/account_messenger'
  end
end
