# frozen_string_literal: true

module Drn
  module Mentoring
    # Resource for loading an application database
    class Database
      include Framework::Application::Resource

      attr_reader :instance

      def [](table_name)
        instance[table_name]
      end

      def load
        @instance = ::Sequel.connect(app.settings[:database_url])
      end
    end
  end
end
