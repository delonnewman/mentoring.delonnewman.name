require 'spec_helper'

RSpec.describe Mentoring::User do
  it 'should reference a UserRole by UserRole#id or a UserRole#name' do
    user0 =
      described_class[
        username: 'tester',
        email: 'tester@example.com',
        role: 'admin'
      ]
    expect(user0.role).to be_an_instance_of Mentoring::UserRole
  end

  describe 'available?' do
    it "should return true if the current time is within the user's schedule" do
      user = described_class[
        username: 'tester',
        email: 'tester@example.com',
        role: 'user',
        meta: { 'profile.availability' => { 2 => { start: 10, end: 17 } } }
      ]
      expect(user).to be_available Time.new(2021, 8, 24, 12, 32)
    end
  end
end
