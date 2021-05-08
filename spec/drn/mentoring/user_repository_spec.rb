require 'spec_helper'

RSpec.describe Drn::Mentoring::UserRepository do
  let(:db) { Drn::Mentoring::App.db }
  let(:users) { described_class.new(db[:users], Drn::Mentoring::User) }

  describe "#find_by" do
    it 'should retrieve a single value or return nil' do
      user = users.find_by(username: 'delon')
      expect(user).not_to be_nil
    end

    it 'should resolve predicate attributes' do
      expect { users.find_by(id: 1) }.not_to raise_error
    end
  end
end
