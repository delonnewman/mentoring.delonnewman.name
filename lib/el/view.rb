module El
  class View
    attr :request, :app

    def self.template_name
      StringUtils.underscore(name.split('::').last.sub(/View$/, '')).to_sym
    end

    def initialize(router)
      @router  = router
      @app     = router.app
      @request = router.request
    end

    def render(code, path)
      binding.eval(code, path)
    end
  end
end
