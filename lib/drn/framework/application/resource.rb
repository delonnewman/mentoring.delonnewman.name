# frozen_string_literal: true

module Drn
  module Framework
    # A stateful resource to be injected into the application
    module Application
      module Resource
        extend Trait
        required :load

        attr_reader :app

        def initialize(app)
          @app = app
        end

        def loaded?
          @loaded
        end

        def load!
          load
          loaded!
        end

        def unload; end

        def unload!
          unload
          unloaded!
        end

        private

        def loaded!
          @loaded = true
        end

        def unloaded!
          @loaded = false
        end
      end
    end
  end
end
