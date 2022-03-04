# frozen_string_literal: true

module El
  module Application
    class Router
      include Dependency
      include Rack::Routable
    end
  end
end
