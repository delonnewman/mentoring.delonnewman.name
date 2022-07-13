# frozen_string_literal: true

module El
  class View
    include TemplateHelpers
    include Memoize
    extend  Pluggable
    extend  Forwardable

    attr_reader :controller, :options

    def_delegators :controller, :app, :request, :module_name
    def_delegators :request, :url_for, :params, :options, :session
    def_delegators :app, :routes

    def initialize(controller, options)
      @controller = controller
      @options    = options
      Memoize.init_memoize_state!(self)
    end

    def template_name
      StringUtils.underscore(self.class.name.split('::').last.sub(/View$/, '')).to_sym
    end

    memoize def templates
      Templates.new(self)
    end

    def render
      templates.template(template_name).eval(binding)
    end
  end
end
