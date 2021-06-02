# frozen_string_literal: true
module Drn
  module Mentoring
    class EntityController
      attr_reader :entity_class, :entity_name, :canonical_name, :controller, :app

      extend Forwardable
      def_delegators :controller, :template_path, :layout_path, :layout

      def self.build(entity_class, **options)
        new(entity_class, **options).build!
      end

      
      def initialize(entity_class, layout: nil, include: nil, controller_super_class: Controller)
        @entity_class   = entity_class
        @entity_name    = @entity_class.canonical_name.freeze
        @canonical_name = Inflection.plural(@entity_name).freeze

        @controller = Class.new(controller_super_class)
        @controller.class_eval("def self.canonical_name; #{@canonical_name.inspect} end", __FILE__)
        @controller.include(include) if include
        @controller.layout layout if layout
      end

      def build!
        define_operation_list
        define_operation_new
        define_operation_create
        define_operation_show
        define_operation_edit
        define_operation_update
        define_operation_delete

        self
      end

      def call(env)
        @app = env.fetch('mentoring.app') do
          raise "mentoring.app key should be set in env before calling a controller"
        end

        @controller.call(env)
      end
      
      def path_list
        "/#{canonical_name}"
      end

      def path_new
        "/#{canonical_name}/new"
      end

      def path_create
        "/#{canonical_name}/create"
      end

      def path_show(ref = ':id')
        ref = ref.id if ref.is_a?(Entity) && ref.respond_to?(:id)
        "/#{canonical_name}/#{ref}"
      end
      alias path_update path_show
      alias path_delete path_show

      def path_edit(id = ':id')
        "#{path_show(id)}/edit"
      end

      INDEX_TEMPLATE = <<~HTML.freeze
        <% attributes = entity_class.attributes.sort_by(&:display_order).reject { |a| a[:display] == false } %>
        <div class="d-flex justify-content-between align-items-center">
          <%= link_to '/admin', '<< Back', class: 'btn btn-link btn-sm' %>
          <h1 style="font-size: 1.5em">User Registrations</h1>
          <%= link_to "/admin/\#{controller_name}/new", "Add \#{humanize entity_class.canonical_name}", class: 'btn btn-sm btn-primary' %>
        </div>
        <table class="table table-striped table-sm" style="font-size: 0.9em">
          <thead>
            <% attributes.each do |attr| %>
              <th scope="col"><%= attr.display_name %></th>
            <% end %>
            <th scope="col"></th>
          </thead>
          <tbody>
            <% entity_repository.each do |entity| %>
              <tr>
        	<% attributes.each do |attr| %>
        	  <td><%= entity.send(attr.name) %></td>
        	<% end %>
        	<td>
        	  <%= link_to "/admin/\#{controller_name}/\#{entity.id}", 'View', class: "btn btn-link btn-sm" %>
        	  <%= link_to "/admin/\#{controller_name}/\#{entity.id}/edit", 'Edit', class: "btn btn-link btn-sm" %>
        	</td>
              </tr>
            <% end %>
          </tbody>
        </table>
      HTML

      def define_operation_list
        name  = canonical_name.to_sym
        klass = @entity_class
        repo  = klass.repository
        @controller.get path_list do
          render :index, with: { entity_repository: repo, entity_class: klass, controller_name: name }
        end
      end

      def define_operation_new
        klass = @entity_class
        @controller.get path_new do
          render :new, with: { errors: EMPTY_HASH, entity_class: klass }
        end
      end

      def define_operation_create
        @controller.post path_create do
          data = entity_data(params)
          # TODO: need to filter attributes in Entity#to_h
          if (errors = @entity_class.errors(data)).empty?
            entity = @entity_class[data]
            @entity_class.repository.store!(entity)
            redirect_to path_list
          else
            render :new, with: { errors: errors, entity_class: @entity_class }
          end
        end
      end

      def define_operation_show
        klass = @entity_class
        name  = @entity_name.to_sym
        @controller.get path_show do
          entity = klass.repository.find_by!(id: params[:id])
          render :show, with: { name => entity }
        end
      end

      def define_operation_edit
        klass = @entity_class
        name  = @entity_name.to_sym
        @controller.get path_edit do
          entity = klass.repository.find_by!(id: params[:id])
          render :edit, with: { errors: EMPTY_HASH, name => entity }
        end
      end

      def define_operation_update
        @controller.post path_update do
          data   = entity_data(params)
          entity = @entity_class.repository.find_by!(id: params[:id])
          if (errors = @entity_class.errors(data)).empty?
            # TODO: add Repository#update!
            @entity_class.repository.update!(params[:id], data)
            redirect_to path_show(params[:id])
          else
            render :edit, with: { errors: errors, @entity_name.to_sym => entity }
          end
        end
      end

      def define_operation_delete
        @controller.delete path_delete do
          # TODO: add Repository#delete!
          @entity_class.repository.delete!(params[:id])
          redirect_to path_list
        end
      end

      private

        def entity_data(params)
          params[@entity_name].transform_keys(&:to_sym)
        end
    end
  end
end
