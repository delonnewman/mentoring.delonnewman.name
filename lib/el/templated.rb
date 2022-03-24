# frozen_string_literal: true

module El
  class Templated
    include Utils

    class << self
      def canonical_name
        parts = name.split('::')
        Utils.underscore(parts[parts.length - 2])
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

    def template_path(name)
      return Pathname.new(name) if !name.is_a?(Symbol) && File.exist?(name)

      app.app_path.join(canonical_name, 'templates', "#{name}.html.erb")
    end

    def app
      raise ":app method is not implemented for #{self.class}"
    end
  end
end
