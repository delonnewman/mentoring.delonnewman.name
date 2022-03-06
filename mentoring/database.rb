# frozen_string_literal: true

module Mentoring
  # Resource for loading an application database
  class Database < Application.Service()
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

    def table_exists?(table)
      instance.table_exists?(table)
    end

    def transaction(&block)
      instance.transaction(&block)
    end

    def fetch(sql, *args, &block)
      instance.fetch(sql, *args, &block)
    end

    def run(sql)
      instance.run(sql)
    end
  end
end
