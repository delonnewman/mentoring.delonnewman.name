require 'spec_helper'

include Drn::Mentoring

RSpec.describe Template do
  class Testing < Controller
  end

  let(:controller) { Testing.new(Utils.mock_request('/')) }

  describe '.path' do
    it "returns a path from within the Templated's template directory if specified with a symbol a string with no '/'" do
      name = [:test, 'test'].sample
      path = Template.path(name, controller)
      expect(path).to eq Drn::Mentoring.app.template_path(
           Testing.canonical_name,
           name
         )
    end

    it 'returns a path from the template directory or absolute path if specified otherwise' do
      path = Template.path('admin/test', controller)
      expect(path).to eq Drn::Mentoring.app.template_path('admin/test')
    end
  end
end
