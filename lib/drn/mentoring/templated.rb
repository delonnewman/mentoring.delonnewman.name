# frozen_string_literal: true
module Drn
  module Mentoring
    class Templated
      class << self
        def template_path
          @template_path ||= Drn::Mentoring.app.root.join('templates', cononical_name)
        end

        def layout_path
          @layout_path ||= Drn::Mentoring.app.root.join('templates', 'layouts', "#{layout}.html.erb")
        end

        def cononical_name
          Utils.snakecase(name.split('::').last)
        end

        def path_name
          "lib/#{Utils.snakecase(name)}.rb"
        end

        def layout(value = nil)
          @layout = value unless value.nil?
          @layout.nil? ? cononical_name : @layout
        end

        def no_layout!
          layout false
        end
      end
    end
  end
end
