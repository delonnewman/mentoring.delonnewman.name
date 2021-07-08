require 'spec_helper'

RSpec.describe Drn::Mentoring::Application do
  context '#dotenv_path' do
    it 'should return the appropriate dotenv_path for the environment' do
      app = described_class.new(:test)
      expect(app.dotenv_path).to eq '.env.test'

      app = described_class.new(:development)
      expect(app.dotenv_path).to eq '.env'
    end
  end

  # context '#init!' do
  #   it 'should initialize the application based on the environment' do
  #     app = described_class.new(:test).init!
  #     expect(app.settings['DATABASE_NAME']).to eq 'mentoring_test'
  #   end
  # end
end
