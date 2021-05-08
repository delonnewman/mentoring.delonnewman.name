require 'spec_helper'

include Drn::Mentoring

RSpec.describe Product do
  let(:product) do
    Product[
      name:        'Test',
      description: 'Testing 1-2-3',
      image_path:  '/img/test.png',
      amount:      100,
      rate:        'per-month',
      meta:        { testing: 123 }
    ]
  end

  describe '#meta' do
    it 'should take a hash store as YAML and return a hash' do
      expect(product.meta).to be_a Hash
      expect(product.meta[:testing]).to be 123
      
      App.products.store!(product)
      pro = App.products.find_by!(name: 'Test')
      expect(pro.meta).to be_a Hash
      expect(pro.meta[:testing]).to be 123
    end
  end
end
