# frozen_string_literal: true

module Mentoring
  # A collection of user objects and methods on that collection
  class UserRepository < El::Repository
    def default_mentor
      @default_mentor ||= find(app.settings[:default_mentor_username])
    end

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
        .join(:sessions, Sequel[:users][:id] => Sequel[:sessions][:mentor_id])
        .where(Sequel.~(ended_at: nil))
        .map(&method(:entity))
    end
  end
end
