module Drn
  module Mentoring
    class UserRegistration < Entity
      primary_key :id, :uuid

      has :username, String, unique: { within: User.repository }
      has :expires_at, Time, default: ->{ Time.now + (5 * 60 * 60) } # expires in 5 hours
      has :activation_key, String, default: ->{ SecureRandom.urlsafe_base64(256) }

      email
      timestamps

      repository do
        def find_active_by_id_and_key(id, key)
          return nil if key.blank?
          
          reg = find_by(id: id)
          if reg && reg.activation_key == key && reg.expires_at > Time.now
            reg
          end
        end
      end

      def user
        User[slice(:username, :email).merge(role: 'customer')]
      end
    end
  end
end
