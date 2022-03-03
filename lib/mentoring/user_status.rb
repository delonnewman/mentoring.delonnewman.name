# frozen_string_literal: true

module Mentoring
  class UserStatus
    BUSY_STATUSES = Set[:in_session, :chatting, :busy].freeze
    STATUSES = (Set[:available, :not_available] + BUSY_STATUSES).freeze

    STATUS_COLORS = {
      available: 'green',
      not_available: 'grey',
      busy: 'red'
    }.freeze

    STATUSES.each do |status|
      define_method "#{status}?" do
        self.status == status
      end
    end

    attr_reader :status

    def initialize(status)
      @status = status.to_sym
      raise "Unknown status: #{@status}" unless STATUSES.include?(@status)
    end

    def busy?
      BUSY_STATUSES.include?(status)
    end

    def color
      return STATUS_COLORS[:busy] if busy?

      STATUS_COLORS[status]
    end
  end
end
