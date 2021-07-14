require 'spec_helper'

include Drn::Framework

class MockAuthController < Controller
  include Authenticable

  def initialize(env)
    super(env)
    @user = @app.users.first
  end

  def current_user
    @user
  end
end

RSpec.describe EntityController do
  let(:entity_class) { User }

  subject(:controller) do
    described_class.build(
      entity_class,
      layout: :admin,
      controller_super_class: MockAuthController
    )
  end

  describe '#entity_class' do
    it 'should be the class given' do
      expect(controller.entity_class).to be entity_class
    end
  end

  describe '#call' do
    it 'should respond to an entity listing request' do
      req = Utils.mock_request(controller.path_list)
      expect(controller.call(req)[2][0]).to match(%r{Users<\/h1>})
    end

    it 'should respond to a new entity request'
    it 'should respond to a create entity request'
    it 'should respond to a show entity request'
    it 'should respond to an edit entity request'
    it 'should respond to an update entity request'
    it 'should respond to a delete entity request'
  end
end
