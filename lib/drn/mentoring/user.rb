module Drn
  module Mentoring
    class User < Entity
      require :username

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
