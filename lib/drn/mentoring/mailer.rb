# frozen_string_literal: true
module Drn
  module Mentoring
    class Mailer < Templated
      include Invokable

      def initialize(app)
        @app = app
      end

      protected
      
      def mail(name, view = EMPTY_HASH, to:, from: 'noreply@delonnewman.name', subject:)
        content = render_erb(name, view)
        msg     = [{ 'From' => from, 'To' => [to], 'Subject' => subject, 'HTMLPart' => content }]
        Concurrent::Promises.future do
          Mailjet::Send.create(messages: msg)
        end
      end
      
      private

      def render_erb(name, __view__)
        __binding__ = binding

        if __view__.is_a?(Hash)
          __data__ = __view__
          __data__.each_pair do |key, value|
            __binding__.local_variable_set(key, value)
          end
        end

        __path__ = self.class.template_path.join("#{name}.html.erb")

        if self.class.layout
          __content__ = eval(template_content(name, __path__), __binding__)
          eval(template_content(:layout, self.class.layout_path), __binding__)
        else
          eval(template_content(name, __path__), __binding__)
        end
      end

      def template_cache
        @template_cache ||= {}
      end

      def template_content(view, path)
        if Drn::Mentoring.app.env == :production && (cached = template_cache[view])
          cached
        else
          code = Erubi::Engine.new(File.read(path)).src
          template_cache[view] = code if Drn::Mentoring.app.env == :production
          code
        end
      end
    end
  end
end
