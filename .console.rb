require_relative 'mentoring/application'

class ApplicationContainer
  attr_reader :app, :server

  def self.create(env)
    new(Mentoring::Application.new(env))
  end

  def initialize(app)
    @app = app
  end

  def init!
    @app.init!
  end

  def start!
    return if running?

    init! unless @app.initialized?

    options = { environment: @app.env.name, DocumentRoot: @app.root_path.join('public'), Port: 3000 }

    @server = nil
    Thread.new do
      Rack::Handler::WEBrick.run(@app.rack, **options) do |s|
        @server = s
      end
    end

    @running = true
  end
  alias run! start!

  def stop!
    return unless running?

    @server.shutdown

    @running = false
  end

  def running?
    @running
  end

  def respond_to_missing?(method, include_all)
    @app.respond_to?(method, include_all)
  end

  def method_missing(method, *args, **kwargs, &block)
    @app.public_send(method, *args, **kwargs, &block)
  end
end

def app(env = ENV.fetch('RACK_ENV', 'development').to_sym)
  @apps ||= {}
  @apps[env] ||= ApplicationContainer.create(env)
end
app.init!

def request_for(path, **options)
  app.routes.match(Rack::MockRequest.env_for(path, options))
end

def request(path, **options)
  app.call(Rack::MockRequest.env_for(path, options))
end

%i[get post delete link put unlink].each do |verb|
  define_singleton_method verb do |*args, **kwargs|
    request(*args, **kwargs.merge(method: verb))
  end
end

def method_query(object:, output:, args: [])
  object.methods.select do |m|
    object.dup.public_send(m, *args) == output
  rescue StandardError => _e
    nil
  end
end
