# frozen_string_literal: true

module El
  class Controller
    attr_reader :router

    def initialize(router)
      @router = router
    end

    def app
      router.app
    end

    def routes
      router.routes
    end

    def render(*args, **kwargs)
      router.render(*args, **kwargs)
    end

    def url_for(*args)
      router.url_for(*args)
    end
  end
end
