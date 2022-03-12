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

    def logger
      app.logger
    end

    def routes
      router.routes
    end

    def request
      router.request
    end

    def redirect_to(*args)
      router.redirect_to(*args)
    end

    def response
      router.response
    end

    def params
      router.params
    end

    def json
      router.json
    end

    def current_user=(user)
      router.current_user = user
    end

    def current_user
      router.current_user
    end

    def authenticated?(**kwargs)
      router.authenticated?(**kwargs)
    end

    def logout!
      router.logout!
    end

    def render(*args, **kwargs)
      router.render(*args, **kwargs)
    end

    def url_for(*args)
      router.url_for(*args)
    end
  end
end
