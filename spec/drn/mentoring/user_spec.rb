require 'spec_helper'

RSpec.describe Drn::Mentoring::User do
  it 'should reference a UserRole by UserRole#id or a UserRole#name' do
    user0 = described_class[username: 'tester', email: 'tester@example.com', role: 'admin']
    expect(user0.role).to be_an_instance_of Drn::Mentoring::UserRole
  end
end
