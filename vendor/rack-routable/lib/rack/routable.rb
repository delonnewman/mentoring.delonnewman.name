# frozen_string_literal: true
require 'stringio'

module Rack
  # Provides a light-weight DSL for routing over Rack, and instances implement
  # the Rack application interface.
  #
  # @example
  #   class MyApp
  #     include Rack::Routable
  #
  #     # compose Rack middleware
  #     use Rack::Session
  #
  #     static '/' => 'public'
  # 
  #     # block routes
  #     get '/hello' do
  #       'Hello'
  #     end
  #
  #     # 'callable' objects also work
  #     get '/hola', ->{ 'Hola' }
  #
  #     class Greeter
  #       def call
  #         'Miredita'
  #       end
  #     end
  #
  #     get '/miredita', Greeter
  #
  #     # dispatch based on headers
  #     get '/hello', content_type: :json do
  #       'Hello JSON'
  #     end
  #
  #     # nested routes
  #     on '/user/:id' do |user_id|
  #       @user = User.find(user_id)
  #
  #       get render: 'user/show'
  #       post do
  #         @user.update(params.slice(:username, :email))
  #       end
  #
  #       get '/settings', render: 'user/settings'
  #       post '/settings do
  #         @user.settings.update(params.slice(:settings))
  #       end
  #     end
  #
  #     # mount Rack apps
  #     mount '/admin', AdminApp
  #   end
  module Routable
    require_relative 'routable/routes'

    # The default headers for responses
    DEFAULT_HEADERS = {
      'Content-Type' => 'text/html'
    }.freeze

    EMPTY_ARRAY = [].freeze
    EMPTY_HASH  = {}.freeze

    private_constant :EMPTY_HASH, :EMPTY_ARRAY

    def self.included(base)
      base.extend(DSL)
      base.include(InstanceMethods)
    end

    # TODO: implement custom query parser

    module DSL
      # A "macro" method to specify paths that should be used to serve static files.
      # They will be served from the "public" directory within the applications root_path.
      # 
      # @param paths [Array<String>]
      def static(mapping)
        url  = mapping.first[0]
        root = mapping.first[1]
        use Rack::TryStatic, root: root, urls: [url], try: %w[.html index.html /index.html]
      end

      # A "macro" method to specify Rack middleware that should be used by this application.
      #
      # @param klass [Class] Rack middleware
      # @param args [Array] arguments for initializing the middleware
      def use(klass, *args)
        @middleware ||= []
        @middleware << [klass, args]
      end

      # Return an array of Rack middleware (used by this application) and their arguments.
      #
      # @return [Array<[Class, Array]>]
      def middleware
        @middleware || EMPTY_ARRAY
      end

      # A "macro" method for specifying the root_path of the application.
      # If called as a class method it will return the value that will be used
      # when instatiating.
      # 
      # @param dir [String]
      # @return [String, nil]
      def root_path(dir = nil)
        @root_path = dir unless dir.nil?
        @root_path || '.'
      end

      # Return the routing table for the class.
      # 
      # @return [Routes]
      def routes
        @routes ||= Routes.new
      end

      # Valid methods for routes
      METHODS = %i[get post delete put head link unlink].to_set.freeze

      # A "macro" method for defining a route for the application.
      #
      # @param method [:get, :post, :delete :put, :head, :link :unlink]
      def route(method, path, **options, &block)
        raise "Invalid method: #{method.inspect}" unless METHODS.include?(method)

        routes.add!(method, path, block, options)
      end

      METHODS.each do |method|
        define_method method do |path, **options, &block|
          route(method, path, **options, &block)
        end
      end

      def mount(prefix, app, **options)
        routes.mount!(prefix, app, options)
      end

      def response(body, status: 200, headers: nil)
        headers = headers ? DEFAULT_HEADERS.merge(headers) : DEFAULT_HEADERS

        Rack::Response.new(StringIO.new(body), status, headers)
      end

      def redirect_to(url)
        Rack::Response.new.tap do |r|
          r.redirect(url)
        end
      end
    end

    module InstanceMethods
      def not_found(env)
        io = StringIO.new
        io.puts "<h1>Not Found</h1>"

        io.puts "<h2>Valid Routes</h2>"
        io.puts "<table><tbody>"
        self.class.routes.each do |method, path, app|
          if method == :mount && app.is_a?(Rack::Routable)
            app.class.routes.each do |method, app_path|
              io.puts "<tr><td>#{method}</td><td>#{path + app_path} => #{app_path}</td>"
            end
          elsif method == :mount
            io.puts "<tr><td>#{method}</td><td>#{path}</td>"
          else
            io.puts "<tr><td>#{method}</td><td>#{path}</td>"
          end
        end
        io.puts "</tbody></table>"

        io.puts "<h2>Environment</h2>"
        io.puts "<table><tbody>"
        env.each do |key, value|
          io.puts "<tr><td>#{key}</td><td>#{value.inspect}</td>"
        end
        io.puts "</tbody></table>"
        
        [404, DEFAULT_HEADERS, [io.string]]
      end

      def error(env)
        [500, DEFAULT_HEADERS, StringIO.new('Server Error')]
      end

      # TODO: add error and not_found to the DSL
      def call(env)
        req   = Request.new(env)
        match = self.class.routes.match(env)

        return not_found(env) unless match

        case match[:tag]
        when :app
          match[:value].call(match[:env])
        when :action
          params = req.params.merge(match[:params])
  
          res = begin
                  # NOTE: consider calling with instance_exec do some benchmarking
                  # to see how this would effect performance.
                  match[:value].call(params, req)
                rescue => e
                  if (env = ENV.fetch('RACK_ENV') { :development }.to_sym) == :production
                    env['rack.routable.error'] = e
                    return error(env)
                  else
                    raise e
                  end
                end
  
          if res.is_a?(Array) && res.size == 3 && res[0].is_a?(Integer) 
            res
          elsif res.is_a?(Response)
            res.to_a
          elsif res.is_a?(Hash) && res.key?(:status)
            [res[:status], res.fetch(:headers) { DEFAULT_HEADERS }, res[:body]]
          elsif res.respond_to?(:each)
            [200, DEFAULT_HEADERS, res]
          else
            [200, DEFAULT_HEADERS, StringIO.new(res.to_s)]
          end
        end
      end
    end
  end
end
