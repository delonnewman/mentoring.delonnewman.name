require 'spec_helper'

RSpec.describe Drn::Mentoring::Application::Main do
  it 'should route to checkout' do
    env = Rack::MockRequest.env_for('/checkout/setup')

    expect(described_class.call(env)).not_to be false
  end
end
