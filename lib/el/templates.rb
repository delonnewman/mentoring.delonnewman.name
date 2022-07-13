# frozen_string_literal: true

module El
  class Templates
    include Memoize

    attr_reader :templated

    def initialize(templated)
      @templated = templated
      Memoize.init_memoize_state!(self)

      freeze
    end

    def app
      templated.app
    end

    def layout
      templated.layout
    end

    def module_name
      templated.module_name
    end

    memoize def template(name)
      Template.new(templated, template_path(name))
    end

    def render_template(name, view)
      template(name)&.call(view)
    end

    def template_path(name)
      return Pathname.new(name) if !name.is_a?(Symbol) && File.exist?(name)

      app.app_path.join(module_name, 'templates', "#{name}.html.erb")
    end
  end
end
