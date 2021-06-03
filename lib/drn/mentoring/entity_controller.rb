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

      
      def attributes
        @attributes ||= entity_class.attributes.sort_by(&:display_order).reject { |a| a[:display] == false }
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

      def define_operation_list
        name  = canonical_name.to_sym
        klass = @entity_class
        repo  = klass.repository
        @controller.get path_list do
          render 'admin/index', with: { entity_repository: repo, entity_class: klass, controller_name: name }
        end
      end

      def define_operation_new
        klass = @entity_class
        @controller.get path_new do
          render 'admin/new', with: { errors: EMPTY_HASH, entity_class: klass }
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
            render 'admin/new', with: { errors: errors, entity_class: @entity_class }
          end
        end
      end

      def define_operation_show
        klass = @entity_class
        name  = @entity_name.to_sym
        @controller.get path_show do
          entity = klass.repository.find_by!(id: params[:id])
          render 'admin/show', with: { entity: entity }
        end
      end

      def define_operation_edit
        klass = @entity_class
        name  = @entity_name.to_sym
        @controller.get path_edit do
          entity = klass.repository.find_by!(id: params[:id])
          render 'admin/edit', with: { errors: EMPTY_HASH, entity: entity }
        end
      end

      def define_operation_update
        klass = entity_class
        entity_name = entity_class.canonical_name
        @controller.post path_update do
          app.logger.info "Update #{entity_name} with params: #{params.inspect}"
          data   = params[entity_name].transform_keys(&:to_sym)
          entity = klass.repository.find_by!(id: params[:id])
          if (errors = klass.errors(data)).empty?
            # TODO: add Repository#update!
            klass.repository.update!(params[:id], data)
            redirect_to "/admin/#{canonical_name}/#{params[:id]}"
          else
            render 'admin/edit', with: { errors: errors, entity: entity }
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
    end
  end
end
