# frozen_string_literal: true

module Drn
  module Mentoring
    class ChatService < Framework::Controller
      require 'websocket/driver'
      require 'pry'

      attr_reader :socket

      def initialize(env)
        super(env)

        @socket = WebSocket.new(env, logger) if ::WebSocket::Driver.websocket?(env)

        logger.info "Initialize chat service..."
      end

      class WebSocket
        attr_reader :env, :url

        def initialize(env, logger)
          @env = env
          scheme = Rack::Request.new(env).ssl? ? 'wss:' : 'ws:'
          @url = "#{scheme}//#{env['HTTP_HOST']}#{env['REQUEST_URI']}"
          @driver = ::WebSocket::Driver.rack(self)

          @io = env['rack.hijack'].call
          logger.info "Socket: #{@io.inspect}, url: #{@url}"
          #binding.pry

          @driver.start

          Thread.new do
            selector = NIO::Selector.new
            selector.register(@io, :rw)
            loop do
              selector.select do |monitor|
                logger.info "Monitor#io #{monitor.io.inspect}"
                case monitor.io
                when TCPSocket
                  if monitor.readable?
                    client = monitor.io.accept_nonblock
                    logger.info "Client: #{client.inspect}"
                  elsif monitor.writeable?
                    monitor.io.write("Hello")
                  else
                    logger.info "Monitor not readable: #{monitor.readiness.inspect}"
                  end
                end
              end
              sleep 0.5
            end
          end
        end

        def write(string)
          @io.write(string)
        end

        def recieve_data(data)
          @driver.parse(data)
        end
      end

      get '/' do
        render plain: 'Hello this is the chat service'
      end
    end
  end
end
