# frozen_string_literal: true

module Mentoring
  # Resource for loading an application database
  class Database < Application.Resource()
    attr_reader :instance

    start do
      @instance = Sequel.connect(app.settings[:database_url])
    end

    def [](table_name)
      instance[table_name]
    end

    def tables
      instance.tables
    end
  end
end
