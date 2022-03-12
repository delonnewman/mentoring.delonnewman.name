# frozen_string_literal: true

module El
  # A collection of utility functions
  module Utils
    module_function

    def mock_request(path, **options)
      Rack::MockRequest.env_for(path, **options).merge('mentoring.app' => Mentoring.app)
    end

    def escape_html(string)
      CGI.escapeHTML(string)
    end
    alias h escape_html

    JS_ESCAPE_MAP = {
      '\\'   => '\\\\',
      '</'   => '<\/',
      "\r\n" => '\n',
      "\n"   => '\n',
      "\r"   => '\n',
      '"'    => '\\"',
      "'"    => "\\'",
      '`'    => '\\`',
      '$'    => '\\$'
    }.freeze

    private_constant :JS_ESCAPE_MAP

    def escape_javascript(javascript)
      javascript = javascript.to_s
      if javascript.empty?
        ''
      else
        javascript.gsub(
          %r{(\\|<\/|\r\n|\342\200\250|\342\200\251|[\n\r"']|[`]|[$])}u,
          JS_ESCAPE_MAP
        )
      end
    end
    alias j escape_javascript

    # Blantantly stolen from active-support
    def underscore(string)
      return string unless /[A-Z-]|::/ =~ string

      word = string.to_s.gsub('::', '/')
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr!('-', '_')
      word.downcase!
      word
    end

    def humanize(string)
      string = string.name if string.is_a?(Symbol)
      return string unless /[\W_]/ =~ string

      string.to_s.gsub(/[\W_]/, ' ')
    end

    def titlecase(string)
      humanize(string).split(' ').map!(&:capitalize).join(' ')
    end

    def camelcase(string, uppercase_first: true)
      string = string.to_s
      string = if uppercase_first
                 string.sub(/^[a-z\d]*/) { |match| match.capitalize }
               else
                 string.sub(/^[A-Z\d]*/) do |match|
                   match[0].downcase!
                   match
                 end
               end
      string.gsub!(%r{(?:_|(/))([a-z\d]*)}i) { Regexp.last_match(2).capitalize.to_s }
      string.gsub!('/', '::')
      string
    end

    def kebabcase(string)
      string
    end

    def entity_name(string)
      Inflection.singular(camelcase(string))
    end

    def table_name(entity_name)
      Inflection.plural(Utils.underscore(entity_name.split('::').last))
    end

    def join_table_name(entity_name, attribute_name)
      Utils.snakecase("#{table_name(entity_name)}_#{attribute_name}")
    end

    def reference_key(attribute_name)
      "#{Inflection.singularize(attribute_name)}_id"
    end

    def constantize(string)
      Mentoring.const_get(string)
    end
  end
end
