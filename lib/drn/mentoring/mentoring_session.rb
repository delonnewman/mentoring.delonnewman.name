# frozen_string_literal: true

module Drn
  module Mentoring
    # Represents the state of a mentoring session
    class MentoringSession < Entity
      primary_key :id, :uuid

      has :checkout_session_id, String
      has :started_at, Time, default: -> { Time.now }
      has :ended_at, Time, required: false

      # TODO: add a way to establish a looser relationship or
      # to select the fields that will be loaded (maybe both?).
      #
      # Also need to add to repository aspects of component attributes
      # if the field is not required it should be an outer join.
      belongs_to :mentor, type: User, default: 'delon'
      belongs_to :customer, type: User

      repository do
        def end!(id)
          update!(id, ended_at: Time.now)
        end

        def for_customer(user)
          user_id = user.is_a?(User) ? user.id : user
          dataset.where(customer_id: user_id)
        end

        def for_mentor(user)
          user_id = user.is_a?(User) ? user.id : user
          dataset.where(mentor_id: user_id)
        end
      end

      def viewable_by?(current_user)
        current_user.id == dig(:customer, :id) || current_user.id == dig(:mentor, :id)
      end

      def complete?
        !incomplete?
      end
      alias ended? complete?

      def incomplete?
        ended_at.nil?
      end
    end
  end
end
