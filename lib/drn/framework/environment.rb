module Drn
  module Framework
    class Environment
      attr_reader :name, :logger, :root_path, :entity_class, :component_class, :settings

      def initialize(name:, logger:, root_path:, entity_class:, component_class:, settings: EMPTY_HASH)
        @name = name
        @logger = logger
        @root_path = root_path
        @entity_class = entity_class
        @component_class = component_class
        @settings = settings
      end
    end
  end
end
