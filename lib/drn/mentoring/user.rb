module Drn
  module Mentoring
    class User < Entity
      has :id,          Integer, required: false
      has :displayname, String,  required: false
      has :username,    String
      has :email,       String
      has :role,        UserRole, resolve_with: { Integer => :id, String => :name }
      has :created_at,  Time, default: ->{ Time.now }
      has :updated_at,  Time, default: ->{ Time.now }

      def to_h
        if key?(:role_id)
          super.except(:role)
        else
          super
            .merge(role_id: role.id)
            .except(:role)
        end
      end

      def encrypted_password
        if (password = self[:password])
          BCrypt::Password.create(password)
        else
          self[:encrypted_password]
        end
      end

      def password
        if (crypted = self[:encrypted_password])
          BCrypt::Password.new(crypted)
        else
          self[:password]
        end
      end

      def mentor?
        self[:mentor] == true
      end

      def admin?
        self[:admin] == true
      end

      def customer?
        self[:customer] == true
      end

      def to_s
        displayname || username
      end
    end
  end
end
