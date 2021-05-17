module Drn
  module Mentoring
    # Load dependencies, environment variables, etc.
    require_relative 'environment'

    def self.init!(env = :development)
      @app = Application.new(env).init!
    end

    def self.app
      @app
    end

  end
end
