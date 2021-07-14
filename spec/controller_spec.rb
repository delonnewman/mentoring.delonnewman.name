require 'spec_helper'

include Drn::Framework

class TestController < Controller
  get '/' do
    status 300
  end

  post '/echo.:format' do
    case params[:format]
    when 'json'
      render json: params
    when 'txt'
      render plain: params
    when 'javascript'
      render javascript: params
    end
  end
end

RSpec.describe Controller do
  describe '#status' do
    it 'will set the status of the response' do
      response = TestController.new(Rack::MockRequest.env_for('/')).call
      expect(response[0]).to be 300
    end
  end

  describe '#render' do
    it 'renders json from Ruby data'
    it 'renders plain text output'
    it 'renders javascript output'
  end
end
