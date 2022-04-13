module Mentoring
  module Admin
    class Router < Application.Router()
      namespace '/admin' do
        get '/', RoutesController, :index

        get '/entities', EntitiesController, :index
        get '/entities/:entity', EntitiesController, :list
        get '/entities/:entity/:id', EntitiesController, :show
      end
    end
  end
end
