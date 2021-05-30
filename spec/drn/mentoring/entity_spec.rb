require 'spec_helper'

RSpec.describe Drn::Mentoring::Entity do
  class Test < Drn::Mentoring::Entity
  end

  class Test2 < Drn::Mentoring::Entity
    has :name
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
  end
end
