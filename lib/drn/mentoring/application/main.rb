# frozen_string_literal: true
module Drn
  module Mentoring
    class Application
      class Main < Controller
        mount '/checkout', Checkout.new
        mount '/session',  InstantSessions.new

        static '/' => root.join('public')

        get '/' do
          render :index
        end
      end
    end
  end
end
