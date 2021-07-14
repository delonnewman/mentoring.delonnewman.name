require 'spec_helper'
include Drn::Mentoring

RSpec.describe Product::InstantHelpPolicy do
  let(:customer) { app.users.find_by!(username: 'the-man-in-black') }
  let(:mentor) { User.repository.find_by!(username: 'delon') }
  let(:product) { Product.repository.find_by!(name: 'Instant Help') }
  subject(:policy) { described_class.new(product, MentoringSession.repository) }

  describe '#disabled?' do
    it 'returns true if there are any active mentoring sessions' do
      MentoringSession.repository.create!(
        checkout_session_id: "testing-#{SecureRandom.uuid}",
        customer: customer,
        mentor_id: mentor.id
      )

      expect(policy.disabled?(mentor)).to be true
    end

    it 'returns true the mentor is not available' do
      MentoringSession.repository.delete_all!

      day = Time.new(2021, 6, 12) # a saturday

      expect(policy.disabled?(mentor, now: day)).to be true
    end
  end
end
