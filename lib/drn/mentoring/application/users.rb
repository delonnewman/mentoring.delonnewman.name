module Drn
  module Mentoring
    class Application
      class Users < AuthenticatedController
        layout :main
        
        get '/' do
          render :index
        end
      end
    end
  end
end
