module Drn
  module Mentoring
    class UserRepository < Repository
      def initialize
        super(db[:users], User)
      end

      def find_or_create_from_auth(auth)
        logger.info "User auth: #{auth.inspect}"
      end

      def find_user_and_authenticate(username:, password:)
        user = find_by(username: username)
        return nil unless user
        return user if user.password == password
        false
      end

      def find_user_and_authenticate!(**kwargs)
        find_user_and_authenticate(**kwargs).tap do |user|
          raise "Invalid user or password" if user.nil?
        end
      end
    end
  end
end
