require 'spec_helper'
include Drn::Mentoring

RSpec.describe OngoingMentoringPolicy do
  let(:product) { Product.repository.find_by!(name: 'Ongoing Mentoring') }
  subject(:policy) { described_class.new(product) }

  describe '#disabled?' do
    it 'returns true if the user already is subscribed to ongoing mentoring' do
      user = User.repository.find_by!(username: 'the-man-in-black')

      expect(policy.disabled?(user)).to be true
    end

    it 'returns true if the mentor already has their maximum number of mentees'
  end
end
