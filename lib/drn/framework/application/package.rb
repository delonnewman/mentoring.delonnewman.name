# frozen_string_literal: true

module Drn
  module Framework
    module Application
      # A collection of methods that extends the application logic by composition
      class Package
        attr_reader :app

        def initialize(app)
          @app = app
        end
      end
    end
  end
end
