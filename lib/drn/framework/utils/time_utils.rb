module Drn
  module Framework
    module TimeUtils
      module_function

      def fmt_date(date, alt = '-')
        return alt unless date

        date.strftime('%m/%d/%Y')
      end

      def fmt_time(time, alt = '-')
        return alt unless time

        time.strftime('%l:%M %p')
      end
    end
  end
end
