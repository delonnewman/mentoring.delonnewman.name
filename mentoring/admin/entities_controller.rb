module Mentoring
  module Admin
    class EntitiesController < ApplicationController
      layout :admin

      def index
        render :entities, with: { entities: app.model.entity_classes }
      end

      def list
        entity_class = app.model.entity_class(params[:entity])
        repository = app.model.repository(params[:entity])

        render :entity_class, with: { entity_class: entity_class, repository: repository }
      end

      def show
        repository = app.model.repository(params[:entity])

        render :entity, with: { entity: repository.find_by!(params.slice(:id)) }
      end
    end
  end
end
