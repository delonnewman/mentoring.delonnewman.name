module Drn
  module Mentoring
    class Main < Framework::Controller
      # Handle product interactions
      class Products < Framework::Controller
        include Framework::Authenticable

        get '/:id/subscribe' do
          app.products.subscribe(params[:id], current_user)

          redirect_to '/dashboard'
        end
      end
    end
  end
end
