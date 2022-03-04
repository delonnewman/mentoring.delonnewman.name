# frozen_string_literal: true

module El
  # A stateful resource to be injected into the application
  module Application
    class Resource < Package
      include Resourcable

      class << self
        attr_reader :loader, :unloader

        def start(&block)
          @loader = block
        end

        def stop(&block)
          @unloader = block
        end
      end

      def initialize(app)
        super(app, freeze: false)
      end

      def load!
        instance_exec(&self.class.loader)
        loaded!
        freeze
      end

      def unload!
        instance_exec(&self.class.loader)
      end
    end
  end
end
