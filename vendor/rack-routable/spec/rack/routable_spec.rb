require 'rack/routable'

RSpec.describe Rack::Routable do
  class Mounted
    include Rack::Routable

    post '/' do
      'posted to /'
    end
  end

  class TestApp
    include Rack::Routable

    mount '/test', ->(env) { env['PATH_INFO'] }
    mount '/mounted', Mounted.new

    get ?/ do
      'root dir'
    end

    get '/user/:id' do |params|
      "get user #{params[:id]}"
    end

    post '/user' do
      'create user'
    end
  end

  let(:app) { TestApp.new }

  describe '#app' do
    it 'should respond to rack requests' do
      env = Rack::MockRequest.env_for('/user/1')
      expect(app.call(env)[2].string).to eq 'get user 1'
    end

    it 'should mount other rack apps' do
      { '/test' => '/', '/test/new' => '/new' }.each_pair do |prefixed, unprefixed|
        env = Rack::MockRequest.env_for(prefixed)
        expect(app.call(env)).to eq unprefixed
      end
    end

    it 'should pass post requests to mounted rack apps' do
      env = Rack::MockRequest.env_for('/mounted')
      env['REQUEST_METHOD'] = 'POST'
      expect(app.call(env)[2].string).to eq 'posted to /'
    end
  end
end
