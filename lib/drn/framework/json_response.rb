# frozen_string_literal: true

module Drn
  module Framework
    class JSONResponse
      SUCCESS = { status: 'success' }.freeze
      ERROR   = { status: 'error' }.freeze

      def initialize(response)
        @response = response
      end

      def render(data)
        @response.tap do |r|
          r.write data.to_json
          r.set_header 'Content-Type', 'application/json'
        end
      end

      def success(data = nil)
        msg = if data
                SUCCESS.merge(data: data)
              else
                SUCCESS
              end

        render(msg)
      end

      def error(message)
        render(ERROR.merge(message: message))
      end
    end
  end
end
