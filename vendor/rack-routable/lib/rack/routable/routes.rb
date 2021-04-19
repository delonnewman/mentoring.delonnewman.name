# frozen_string_literal: true
module Rack
  module Routable
    # A routing table--collects routes, and matches them against a given Rack environment.
    #
    # @api private
    # @todo Add header matching
    class Routes
      def initialize
        @table = {}
      end
  
      # Add a route to the table.
      #
      # @param method [Symbol]
      # @param path [String]
      # @param action [#call]
      # @param headers [Hash]
      #
      # @return [Routes]
      def add!(method, path, action, headers = EMPTY_HASH)
        # TODO: Add Symbol#name for older versions of Ruby
        method = method.name.upcase
        table[method] ||= []
        table[method] << [parse_path(path), action]
        self
      end
  
      # Match a route in the table to the given Rack environment.
      #
      # @param env [Hash] a Rack environment
      #
      # @return [{ action: #call, params: Hash }]
      def match(env)
        method = env['REQUEST_METHOD']

        path   = env['PATH_INFO']
        path   = path.start_with?('/') ? path[1, path.size] : path
        parts  = path.split(/\/+/)

  
        routes = @table[method]
        return if routes.nil?
  
        routes.each do |(route, action)|
          if (params = match_path(parts, route))
            return { action: action, params: params }
          end
        end
  
        false
      end
  
      private
  
      def parse_path(str)
        str   = str.start_with?('/') ? str[1, str.size] : str
        names = []
  
        route = str.split(/\/+/).each_with_index.map do |part, i|
          if part.start_with?(':')
            names[i] = part[1, part.size].to_sym
            NAME_PATTERN
          elsif part.end_with?('*')
            /^#{part[0, part.size - 1]}/i
          else
            part
          end
        end
  
        { names: names, path: route }
      end

      def match_path(path, route)
        return false if path.size != route[:path].size
  
        pattern = route[:path]
        names   = route[:names]
        params  = {}
  
        path.each_with_index do |part, i|
          return false unless pattern[i] === part
          if (name = names[i])
            params[name] = part
          end
        end
  
        params
      end
  
      NAME_PATTERN = /\A\w+\z/.freeze
      private_constant :NAME_PATTERN
    end
  end
end
