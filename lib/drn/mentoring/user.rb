# frozen_string_literal: true

module Drn
  module Mentoring
    # Represent users of the system
    class User < Framework::Entity
      primary_key :id
      reference :username, String, unique: true, display: { order: 1 }
      has :mentor, :boolean, required: false, display: { name: 'Is Mentor' }

      has :displayname, String, required: false, display: { name: 'Name', order: 0 }
      belongs_to :role, display: { order: 3 }

      has :meta, Hash, serialize: true, default: EMPTY_HASH

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

        def mentors
          where(mentor: true)
        end
      end

      def availability_schedule
        meta.fetch('profile.availability') { EMPTY_HASH }
      end

      def available?(now = Time.now)
        day = availability_schedule[now.wday]
        return false unless day

        now.hour >= day[:start] && now.hour <= day[:end]
      end

      def status
        return :not_available unless available?

        :available
      end

      def name
        displayname || username
      end
      alias to_s name

      def first_name
        displayname.split(/\s+/).first || username
      end

      def admin?
        role?(:admin)
      end

      def role?(name)
        name = name.is_a?(Symbol) ? name.name : name
        role.name == name
      end
    end
  end
end
