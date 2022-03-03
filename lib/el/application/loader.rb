# frozen_string_literal: true

module El
  module Application
    # A resource for handling code loading
    class Loader
      include Resource

      attr_reader :instance

      def reload!
        instance.reload
      end

      INFLECTIONS = {
        'json_response' => 'JSONResponse'
      }.freeze

      IGNORE_PATHS = [
        '**/templates',
        '**/core_ext.rb',
        '**/layouts'
      ].freeze

      COLLAPSE_PATHS = [
        '**/resources'
      ].freeze

      def load
        @instance = Zeitwerk::Loader.new
        @instance.inflector.inflect(INFLECTIONS)

        init_app_paths
        init_ignore_paths
        init_collapse_paths

        @instance.enable_reloading if app.development?
        @instance.setup
        @instance.eager_load
      end

      private

      def init_app_paths
        @instance.push_dir(app.lib_path, namespace: app.class.app_module)
        @instance.push_dir(app.app_path, namespace: app.class.app_module)
      end

      def init_ignore_paths
        IGNORE_PATHS.each do |path|
          @instance.ignore(path)
        end
      end

      def init_collapse_paths
        COLLAPSE_PATHS.each do |path|
          @instance.collapse(path)
        end
      end
    end
  end
end
