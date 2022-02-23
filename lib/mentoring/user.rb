# frozen_string_literal: true

module Mentoring
  # Represent users of the system
  class User < Drn::Framework::Entity
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

      def add_stripe_customer_id!(id:, stripe_id:)
        user = find_by!(id: id)
        update!(id, meta: user.meta.merge('stripe.customer_id' => stripe_id))
      end

      def mentors
        where(mentor: true)
      end

      def mentors_not_in_sessions
        dataset
          .join(:mentoring_sessions, Sequel[:users][:id] => Sequel[:mentoring_sessions][:mentor_id])
          .where(Sequel.~(ended_at: nil))
          .map { |record| SqlUtils.build_entity(User, record) }
      end
    end

    def availability_schedule
      meta.fetch('profile.availability') { EMPTY_HASH }
    end

    def available?(now: Time.now)
      day = availability_schedule[now.wday]
      return false unless day

      now.hour >= day[:start] && now.hour <= day[:end]
    end

    def currently_available?(sessions:)
      available? && sessions.active_sessions(for_mentor: self).empty?
    end

    def status
      return :not_available unless available?

      :available
    end

    def name
      displayname || username
    end
    alias to_s name

    def stripe_description
      "#{name} (mentoring customer)"
    end

    def stripe_customer_id
      meta.fetch('stripe.customer_id')
    end

    def stripe_customer_id?
      !!meta['stripe.customer_id']
    end

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
