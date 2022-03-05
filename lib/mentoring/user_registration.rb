# frozen_string_literal: true

module Mentoring
  class UserRegistration < Application.Entity()
    primary_key :id, :uuid, display: { order: 0 }

    has :username, String, display: { order: 1 }, unique: { within: User.repository }
    has :expires_at, Time, display: { order: 4 }, default: -> { Time.now + (5 * 60 * 60) } # expires in 5 hours

    has :activation_key, String, display: { order: 3 }, default: -> { SecureRandom.urlsafe_base64(256) }

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
