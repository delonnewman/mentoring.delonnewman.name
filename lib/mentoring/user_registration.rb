# frozen_string_literal: true

module Mentoring
  class UserRegistration < Application.Entity()
    primary_key :id, :uuid

    has :username, :string, unique: { within: User.repository }
    has :expires_at, :time, default: -> { 5.hours.from_now } # expires in 5 hours

    has :activation_key, :string, default: -> { SecureRandom.urlsafe_base64(256) }

    email display: { order: 2 }
    timestamps

    repository do
      def find_active_by_id_and_key(id, key)
        return nil if key.blank?

        reg = find_by(id: id)
        reg if reg&.activation_key == key && reg.expires_at > Time.now
      end
    end
  end
end
