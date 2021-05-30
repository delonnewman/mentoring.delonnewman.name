require 'spec_helper'

RSpec.describe Drn::Mentoring::Entity do
  class Test < Drn::Mentoring::Entity
  end

  class Test2 < Drn::Mentoring::Entity
    has :name
  end

  class Test3 < Drn::Mentoring::Entity
    has :number, Integer
  end

  describe '.valid?' do
    it 'should return false if given an empty value' do
      expect(Test.valid?({})).to be false
    end

    it 'should return true if entity has no attributes and the value is not empty' do
      expect(Test.valid?(test: 1)).to be true
    end

    it 'should return false if the entity has attributes and the value is not valid' do
      expect(Test2.valid?(test: 1)).to be_falsy
    end

    it 'should return true if the entity has attributes and the value is valid' do
      expect(Test2.valid?(name: 'Tester')).to be true
    end

    it 'should accept an entity instance with the right shape' do
      expect(Test2.valid?(Test2[name: 'Tester'])).to be true
      expect(Test3.valid?(Test3[number: 1])).to be true
    end
  end

  describe '.errors' do
    it 'should return an empty hash if there are no errors' do
      expect(Test.errors({})).to be_empty
      expect(Test.errors(test: 1)).to be_empty
      expect(Test2.errors(name: "testing")).to be_empty
      expect(Test3.errors(number: 1)).to be_empty
    end

    it 'should return a hash of errors if the given data is not valid' do
      errors = Test2.errors(test: 1)
      expect(errors).not_to be_empty
      expect(errors[:name]).not_to be_empty
      expect(errors[:name][0]).to eq 'Name is required'

      errors = Test3.errors(number: 'test')
      expect(errors).not_to be_empty
      expect(errors[:number]).not_to be_empty
      expect(errors[:number][0]).to eq 'Number is not valid'
    end
  end
end
