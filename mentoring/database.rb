# frozen_string_literal: true

module Mentoring
  # Resource for loading an application database
  class Database < Application.Service()
    extend Forwardable

    def_delegators :instance, :[], :tables, :table_exists?, :transaction, :fetch, :run

    start do
      @instance = Sequel.connect(app.settings[:database_url])
    end

    private

    attr_reader :instance
  end
end
