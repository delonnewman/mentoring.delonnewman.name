require 'spec_helper'
include Mentoring

RSpec.describe Product::OngoingMentoringPolicy do
  let(:product) { app.products.find_by!(name: 'Ongoing Mentoring') }
  subject(:policy) { described_class.new(product) }

  describe '#disabled?' do
    it 'returns true if the user already is subscribed to ongoing mentoring' do
      user = User.repository.find_by!(username: 'the-man-in-black')

      app.products.subscribe(product, user)

      expect(policy.disabled?(user)).to be true
    end

    it 'returns true if the mentor already has their maximum number of mentees'
  end
end
