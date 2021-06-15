module Drn
  module Mentoring
    class Product < Entity
      # Represents the policies for the "Instant" products
      class InstantHelpPolicy
        attr_reader :product, :mentoring_sessions

        def initialize(product, mentoring_sessions:)
          @product = product
          @mentoring_sessions = mentoring_sessions
        end

        INSTANT_HELP_AVAILABILITY = {
          1 => { start: 10, end: 17 },
          3 => { start: 13, end: 17 },
          4 => { start: 10, end: 17 },
          5 => { start: 10, end: 17 }
        }.freeze

        # Return true if there are any active mentoring sessions
        # and if the mentor is available the current time.
        #
        # @option now [Time]
        # @option availability [Hash<Integer, { start: Integer, end: Integer }>]
        def disabled?(_, now: Time.now, availability: INSTANT_HELP_AVAILABILITY)
          return true unless mentoring_sessions.empty?

          day = availability[now.wday]
          return true unless day

          now.hour < day[:start] || now.hour > day[:end]
        end
      end
    end
  end
end
