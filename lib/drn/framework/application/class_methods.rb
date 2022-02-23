# frozen_string_literal: true

module Drn
  module Framework
    module Application
      # Macro and meta methods for application configuration
      module ClassMethods
        def settings
          @settings ||= {}
        end

        def set(key, value)
          settings[key] = value
        end

        def enable(key)
          set(key, true)
        end

        def disable(key)
          set(key, false)
        end

        def from_env(*keys)
          keys.each do |key|
            settings_from_environment << key.to_s.upcase
          end
        end

        def settings_from_environment
          @settings_from_environment ||= []
        end

        def root_path(path = nil)
          return @root_path unless path

          @root_path = path
        end

        def resource(klass)
          resources << klass
        end

        def resources
          @resources ||= [Application::Settings, Application::Loader]
        end

        def package(klass)
          packages << klass
        end

        def packages
          @packages ||= []
        end
      end
    end
  end
end
