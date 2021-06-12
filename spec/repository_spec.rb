require 'spec_helper'
include Drn::Mentoring

RSpec.describe Repository do
  let(:db) { Drn::Mentoring.app.db }
  let(:users) { described_class.new(db[:users], Drn::Mentoring::User) }

  describe '#find_by' do
    it 'should retrieve a single value or return nil' do
      user = users.find_by(username: 'delon')
      expect(user).not_to be_nil
    end

    it 'should resolve predicate attributes' do
      expect { users.find_by(id: 1) }.not_to raise_error
    end
  end
end
