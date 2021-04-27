module Drn
  module Mentoring
    module Utils
      module_function

      def snakecase(string)
        string
      end
  
      def camelcase(string)
        string
      end
  
      def kebabcase(string)
        string
      end
  
      def pluralize(number, string)
        if number == 1
          "#{number} #{string}"
        else
          "#{number} #{Inflection.plural string}"
        end
      end
  
      YEAR_IN_SECONDS  = 31104000
      MONTH_IN_SECONDS = 2592000
      WEEK_IN_SECONDS  = 604800
      DAY_IN_SECONDS   = 86400
      HOUR_IN_SECONDS  = 3600
  
      def time_ago_in_words(time)
        diff   = Time.now - time
        suffix = diff < 0 ? 'from now' : 'ago'
        diff_  = diff.abs
  
        if diff_ > YEAR_IN_SECONDS
          "#{pluralize (diff_ / YEAR_IN_SECONDS).floor, 'year'} #{suffix}"
        elsif diff_ > MONTH_IN_SECONDS
          "#{pluralize (diff_ / MONTH_IN_SECONDS).floor, 'month'} #{suffix}"
        elsif diff_ > WEEK_IN_SECONDS
          "#{pluralize (diff_ / WEEK_IN_SECONDS).floor, 'week'} #{suffix}"
        elsif diff_ > DAY_IN_SECONDS
          "#{pluralize (diff_ / DAY_IN_SECONDS).floor, 'day'} #{suffix}"
        elsif diff_ > HOUR_IN_SECONDS
          "#{pluralize (diff_ / HOUR_IN_SECONDS).floor, 'hour'} #{suffix}"
        elsif diff_ > 60
          "#{pluralize (diff_ / 60).floor, 'minute'} #{suffix}"
        else
          'just now'
        end
      end
    end
  end
end
