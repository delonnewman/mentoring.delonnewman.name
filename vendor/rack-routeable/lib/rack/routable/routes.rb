module Rack
  module Routable
    class Routes
      def initialize
        @table = {}
      end

      def add!(method, path, action, headers = EMPTY_HASH)
        table[method] ||= []
        table[method] << [parse_path(path), action]
        self
      end
  
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

      def match(method, path)
        path  = path.start_with?('/') ? path[1, path.size] : path
        parts = path.split(/\/+/)
  
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
