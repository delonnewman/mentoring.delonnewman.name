# frozen_string_literal: true

module Drn
  module Mentoring
    # Represent users of the system
    class User < Entity
      primary_key :id
      reference :username, String, unique: true, display: { order: 1 }

      has :displayname,
          String,
          required: false,
          display: {
            name: 'Name',
            order: 0
          }
      belongs_to :role, display: { order: 3 }
      has_many :products

      email display: { order: 2 }
      password

      timestamps

      repository do
        def find_user_and_authenticate(username:, password:)
          user = find_by(username: username)
          return nil unless user
          return user if user.password == password

          false
        end

        def find_user_and_authenticate!(**kwargs)
          find_user_and_authenticate(**kwargs).tap do |user|
            raise 'Invalid user or password' if user.nil?
          end
        end
      end

      def name
        displayname || username
      end
      alias to_s name

      def first_name
        displayname.split(/\s+/).first || username
      end

      def admin?
        role.name == 'admin'
      end
    end
  end
end
