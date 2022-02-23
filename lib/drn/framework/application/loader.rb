# frozen_string_literal: true

module Drn
  module Framework
    module Application
      # A resource for handling code loading
      class Loader
        include Resource

        attr_reader :instance

        def reload!
          instance.reload
        end

        def load
          @instance = Zeitwerk::Loader.new

          @instance.push_dir(app.lib_path)
          @instance.push_dir(app.app_path)
          # @instance.enable_reloading if app.development?

          @instance.setup
        end
      end
    end
  end
end
