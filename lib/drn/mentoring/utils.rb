module Drn
  module Mentoring
    module Utils
      module_function

      def mock_request(path, **options)
        Rack::MockRequest.env_for(path, **options).merge(
          'mentoring.app' => Drn::Mentoring.app
        )
      end

      def money(amount, unit: '$')
        "#{unit}#{sprintf "%.2f", amount}"
      end

      def html_escape(string)
        CGI.escapeHTML(string)
      end
      alias h html_escape
      
      JS_ESCAPE_MAP = {
        '\\'    => '\\\\',
        "</"    => '<\/',
        "\r\n"  => '\n',
        "\n"    => '\n',
        "\r"    => '\n',
        '"'     => '\\"',
        "'"     => "\\'",
        "`"     => "\\`",
        "$"     => "\\$"
      }

      private_constant :JS_ESCAPE_MAP

      def javascript_escape(javascript)
        javascript = javascript.to_s
        if javascript.empty?
          result = ""
        else
          result = javascript.gsub(/(\\|<\/|\r\n|\342\200\250|\342\200\251|[\n\r"']|[`]|[$])/u, JS_ESCAPE_MAP)
        end
      end
      alias j javascript_escape

      # Blantantly stolen from active-support
      def snakecase(string)
        return string unless /[A-Z-]|::/ =~ string
        word = string.to_s.gsub("::", "/")
        word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
        word.tr!("-", "_")
        word.downcase!
        word
      end

      def humanize(string)
        return string unless /[\W_]/ =~ string
        string.to_s.gsub(/[\W_]/, ' ')
      end

      def titlecase(string)
        humanize(string).capitalize
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
