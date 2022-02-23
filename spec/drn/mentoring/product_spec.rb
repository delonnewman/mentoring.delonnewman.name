require 'spec_helper'
include Mentoring

RSpec.describe Product do
  let(:product) do
    Product[
      name: 'Test',
      description: 'Testing 1-2-3',
      image_path: '/img/test.png',
      amount: 100,
      rate: 'per-month',
      meta: {
        stripe_price_id: 123
      }
    ]
  end

  describe '#meta' do
    # Clean up stored product records
    after :each do
      Mentoring.app.products.delete_where!(name: 'Test')
    end

    it 'should take a hash store as YAML and return a hash' do
      expect(product.meta).to be_a Hash
      expect(product.meta[:stripe_price_id]).to be 123

      Mentoring.app.products.store!(product)
      pro = Mentoring.app.products.find_by!(name: 'Test')

      expect(pro.meta).to be_a Hash
      expect(pro.meta[:stripe_price_id]).to be 123
    end
  end
end
