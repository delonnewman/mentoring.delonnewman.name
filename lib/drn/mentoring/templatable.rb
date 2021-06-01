module Drn
  module Mentoring
    module Templatable
      def template_cache
        @template_cache ||= {}
      end

      def template(name)
        template_cache[name] ||= Template[self, name]
      end

      def render_template(name, view = EMPTY_HASH)
        template(name).call(view)
      end
    end
  end
end
