# frozen_string_literal: true
module Rack
  # Provides a light-weight DSL for routing over Rack.
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
    EMPTY_ARRAY = [].freeze
    EMPTY_HASH  = {}.freeze

    private_constant :EMPTY_HASH, :EMPTY_ARRAY

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

      # Return the raw route data for the application.
      # 
      # @return [Array<Array<[Symbol, String, Hash, Proc]>>]
      def routes
        @routes || EMPTY_ARRAY
      end

      # Valid methods for routes
      METHODS = %i[get post delete put head link unlink].to_set.freeze

      # A "macro" method for defining a route for the application.
      #
      # @param method [:get, :post, :delete :put, :head, :link :unlink]
      def route(method, path, **options, &block)
        raise "Invalid method: #{method.inspect}" unless METHODS.include?(method)

        @routes ||= Routes.new
        @routes.add!(method, path, block, options)
      end

      METHODS.each do |method|
        define_method method do |path, **options, &block|
          route(method, path, **options, &block)
        end
      end
    end

    module InstanceMethods
      def call(env)
        req   = request(env)
        match = router.match(req[:method], req[:path])

        return Response.new(404, EMPTY_HASH, ['Not Found']) unless match
        params = req[:params].merge(match[:params])
        res    = match[:action].call(params, req)

        if res.is_a?(Hash) && res.key?(:status)
          Response.new(res[:status], res.fetch(:headers) { EMPTY_HASH }, res.fetch(:body) { EMPTY_ARRAY })
        elsif res.respond_to?(:each)
          Response.new(200, EMPTY_HASH, res)
        else
          Response.new(200, EMPTY_HASH, [res.to_s])
        end
      end
    end
  end
end
