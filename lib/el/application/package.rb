# frozen_string_literal: true

module El
  module Application
    class Package
      include Dependency

      def self.add_to!(app_class, name: Utils.underscore(self.name.split('::').last))
        super(app_class)

        app_class.add_dependency!(name, self)

        pkg = self
        app_class.define_method(name) do
          @packages[name] ||= pkg.new(self)
        end
      end

      attr_reader :app

      def initialize(app)
        @app = app
      end
    end
  end
end
