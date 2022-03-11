# frozen_string_literal: true

module El
  class JSONResponse
    SUCCESS = { status: 'success' }.freeze
    ERROR   = { status: 'error' }.freeze

    def initialize(response)
      @response = response
    end

    def render(data, status: nil)
      @response.tap do |r|
        r.write data.to_json
        r.set_header 'Content-Type', 'application/json'
        r.status = status if status
      end
    end

    def success(data = nil, **options)
      msg = if data
              SUCCESS.merge(data: data)
            else
              SUCCESS
            end

      render(msg, **options)
    end

    def error(message, **options)
      render(ERROR.merge(message: message), **options)
    end
  end
end
