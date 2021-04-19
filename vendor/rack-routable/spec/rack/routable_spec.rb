require 'rack/routable'

RSpec.describe Rack::Routable do
  class TestApp
    include Rack::Routable

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
      expect(app.call(env)).to eq [200, {}, 'get user 1']
    end
  end
end
