require 'spec_helper'
include Drn::Framework

RSpec.describe Entity::Attribute do
  # describe '#join_table_name' do
  #   it 'returns nil if the attribute is not many' do
  #     expect(Product.attribute(:name).join_table_name).to be nil
  #   end
  #   it 'returns a symbol join table name if the attribute is many' do
  #     expect(Product.attribute(:users).join_table_name).to be :users_products
  #   end
  # end
  # describe '#join_table' do
  #   it 'returns nil if the attrbute is not many' do
  #     expect(Product.attribute(:name).join_table).to be nil
  #   end
  #   it 'returns a Sequel::Dataset for the table based on the join_table_name' do
  #     table = Product.attribute(:users).join_table
  #     expect(table).to be_a Sequel::Dataset
  #   end
  # end
end
