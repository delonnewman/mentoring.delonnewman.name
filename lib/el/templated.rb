# frozen_string_literal: true

module El
  class Templated
    include Utils
    include Templatable

    class << self
      def canonical_name
        Utils.underscore(name.split('::').last)
      end

      def layout(value = nil)
        @layout = value unless value.nil?
        @layout.nil? ? canonical_name : @layout
      end
    end

    %i[layout canonical_name].each do |method|
      define_method method do
        self.class.send(method)
      end
    end

    def template_cache
      @template_cache ||= {}
    end

    def template_path(name)
      return Pathname.new(name) if !name.is_a?(Symbol) && File.exist?(name)

      app.app_path.join(canonical_name, 'templates', "#{name}.html.erb")
    end

    def template(name)
      template_cache[name] ||= Template[self, template_path(name)]
    end

    def render_template(name, view = EMPTY_HASH)
      template(name).call(view)
    end

    def app
      raise ":app method is not implemented for #{self.class}"
    end
  end
end
