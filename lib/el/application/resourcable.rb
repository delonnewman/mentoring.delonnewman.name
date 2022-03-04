module El
  module Application
    module Resourcable
      attr_reader :app

      def initialize(app)
        @app = app
      end

      def load!
        raise 'A load! method must be defined'
      end

      def loaded?
        @loaded
      end

      protected

      def loaded!
        @loaded = true
      end
    end
  end
end
