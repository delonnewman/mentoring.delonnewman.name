module El
  class View
    include TemplateHelpers

    attr_reader :request, :app

    def self.template_name
      StringUtils.underscore(name.split('::').last.sub(/View$/, '')).to_sym
    end

    def initialize(router, request)
      @router  = router
      @app     = router.app
      @request = request
    end

    def render(code, path)
      binding.eval(code, path)
    end
  end
end
