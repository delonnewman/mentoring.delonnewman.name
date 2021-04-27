require 'rack/routable'

RSpec.describe Rack::Routable do
  class TestApp
    include Rack::Routable

    mount '/test', ->(env) { env['PATH_INFO'] }

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
      %w{ /test /test/new }.each do |path|
        env = Rack::MockRequest.env_for(path)
        expect(app.call(env)).to eq path
      end
    end
  end
end
