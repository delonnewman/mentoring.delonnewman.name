module El
  class View
    include TemplateHelpers
    include Memoize
    extend  Pluggable
    extend  Forwardable

    class << self
      alias call_without_processors new
      alias call new

      def call_with_processors(router, request)
        request ||= apply_before_processors(router.app, request)
        new(router, request)
      end

      def apply_before_processors(app, request)
        return request unless (procs = processors[:before])

        procs.reduce(request) do |req, p|
          p.call(app, req) || req
        end
      end

      def processors
        procs = @processors ||= {}

        procs.merge!(superclass.processors) if superclass.respond_to?(:processors)

        procs
      end

      def freeze
        processors.freeze
        self
      end

      # Class DSL methods

      def define_before_processor(callable = nil, &block)
        processors[:before] ||= []
        processors[:before] << callable || block
        class << self
          undef_method :call
          alias_method :call, :call_with_processors
        end
      end
      alias before define_before_processor
    end

    def self.template_name
      StringUtils.underscore(name.split('::').last.sub(/View$/, '')).to_sym
    end

    attr_reader :request, :app

    def_delegators :request, :url_for, :params, :options, :session
    def_delegators :app, :routes

    def initialize(app, request)
      @app = app
      @request = request
      Memoize.init_memoize_state!(self)
    end

    def render(code, path)
      binding.eval(code, path)
    end
  end
end
