require 'spec_helper'

RSpec.describe Drn::Mentoring::Mailer do
  class TestMailer < Drn::Mentoring::Mailer
    def test
      "testing"
    end
  end

  describe TestMailer do
    it 'should return the result of the mailer action' do
      mailer = described_class.new(Drn::Mentoring.app)
      expect(mailer.test).to eq 'testing'
    end
  end
end
