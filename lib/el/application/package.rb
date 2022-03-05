# frozen_string_literal: true

module El
  module Application
    class Package
      include Dependency

      attr_reader :app

      def self.add_to!(app_class)
        super(app_class)

        name = Utils.underscore(self.name.split('::').last).to_sym
        app_class.add_dependency!(name, self, kind: :packages)

        app_class.define_method(name) do
          packages.fetch(name)
        end
      end

      def initialize(app)
        @app = app
        freeze
      end
    end
  end
end
