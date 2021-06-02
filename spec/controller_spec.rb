require 'spec_helper'

include Drn::Mentoring

RSpec.describe Controller do
  describe "#status" do
    it 'will set the status of the response'
  end

  describe '#render' do
    it 'renders json from Ruby data'
    it 'renders plain text output'
    it 'renders javascript output'
  end
end
