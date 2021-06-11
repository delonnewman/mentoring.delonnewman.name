require 'spec_helper'
include Drn::Mentoring

RSpec.describe InstantHelpPolicy do
  let(:customer) { 'the-man-in-black' }
  let(:product) { Product.repository.find_by!(name: 'Instant Help') }
  subject(:policy) do
    described_class.new(product: product, mentoring_sessions: MentoringSession.repository)
  end

  describe '#disabled?' do
    it 'returns true if there are any active mentoring sessions' do
      MentoringSession.repository.create!(checkout_session_id: "testing-#{SecureRandom.uuid}", customer: customer)

      expect(policy).to be_disabled
    end
  end
end
