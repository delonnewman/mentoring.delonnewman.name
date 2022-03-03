# frozen_string_literal: true

module Mentoring
  # Resource for loading an application database
  class Database
    include Drn::Framework::Application::Resource

    attr_reader :instance

    def [](table_name)
      instance[table_name]
    end

    def tables
      instance.tables
    end

    def load
      @instance = Sequel.connect(app.settings[:database_url])
    end
  end
end
