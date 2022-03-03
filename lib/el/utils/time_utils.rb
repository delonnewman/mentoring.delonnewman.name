# frozen_string_literal: true

module El
  # A collection of date / time utilities
  module TimeUtils
    require_relative 'duration'
    require_relative 'rate'

    module_function

    def fmt_date(date, alt = '-')
      return alt unless date

      date.strftime('%m/%d/%Y')
    end

    def fmt_time(time, alt = '-')
      return alt unless time

      time.strftime('%l:%M %p')
    end

    Duration::UNITS.each_key do |unit|
      module_eval <<~CODE, __FILE__, __LINE__ + 1
        module_function def #{unit}(magnitude)
          Duration[magnitude, #{unit.inspect}]
        end
      CODE
    end
  end
end
