module El
  class View
    include TemplateHelpers
    extend Pluggable

    attr_reader :request

    def self.template_name
      StringUtils.underscore(name.split('::').last.sub(/View$/, '')).to_sym
    end

    def initialize(router, request)
      @router  = router
      @request = @request = self.class.apply_plugins(app, request)
    end

    def app
      @router.app
    end

    def render(code, path)
      binding.eval(code, path)
    end
  end
end
