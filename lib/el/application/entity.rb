# frozen_string_literal: true

module El
  module Application
    class Entity < El::Entity
      include Dependency

      class << self
        def add_to!(app_class)
          super(app_class)

          name = Utils.underscore(self.name.split('::').last).to_sym
          app_class.add_dependency!(name, self, kind: :entities)

          app_class.define_method(name) do
            entities.fetch(name)
          end

          define_repositories_method!
        end

        def init_app!(app, entity_class)
          define_repository_accessor!(app, entity_class, init_repository!(app, entity_class))
        end

        private

        def define_repositories_method!
          return if app_class.method_defined?(:repositories)

          app_class.define_method :repositories do
            @repositories ||= {}
          end
        end

        def init_repository!(app, entity_class)
          app.repositories[entity_class] = entity_class.repository_class.new(
            app,
            entity_class
          )
        end

        def define_repository_accessor!(app, entity_class, repository)
          method_name = Inflection.plural(Utils.underscore(entity_class.name.split('::').last))
          var_name = "@#{method_name}"

          app.instance_variable_set(var_name, repository)

          app.define_singleton_method method_name do
            app.instance_variable_get(var_name)
          end
        end
      end
    end
  end
end
