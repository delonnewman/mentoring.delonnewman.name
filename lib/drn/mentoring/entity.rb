module Drn
  module Mentoring
    # Represents a domain entity that will be modeled. Provides dynamic checks and
    # meta objects for relfection which is used to drive productivity and inspection tools.
    class Entity < HashDelegator
      transform_keys(&:to_sym)
      extend Forwardable

      CLASSICAL_TYPE = ->(klass) { ->(v) { v.is_a?(klass) } }
      DEFAULT_TYPE   = CLASSICAL_TYPE[Object]
      REGEXP_TYPE    = ->(regex) { ->(v) { v.is_a?(String) && !!(regex =~ v) } }
      UUID_REGEXP    = /\A[0-9A-Fa-f]{8,8}\-[0-9A-Fa-f]{4,4}\-[0-9A-Fa-f]{4,4}\-[0-9A-Fa-f]{4,4}\-[0-9A-Fa-f]{12,12}\z/.freeze

      SPECIAL_TYPES = {
        boolean: ->(v) { v.is_a?(FalseClass) || v.is_a?(TrueClass) },
        string:  CLASSICAL_TYPE[String],
        any:     CLASSICAL_TYPE[BasicObject],
        uuid:    REGEXP_TYPE[UUID_REGEXP]
      }

      # Represents an attribute of a domain entity. Drives dynamic checks and provides
      # meta objects for reflection.
      class Attribute < HashDelegator
        require :entity, :name, :required, :type

        def required?
          self[:required] == true
        end

        def optional?
          !required?
        end

        def default
          self[:default]
        end

        def type
          t = self[:type]

          return t                 if t.respond_to?(:call)
          return CLASSICAL_TYPE[t] if t.is_a?(Class)
          return REGEXP_TYPE[t]    if t.is_a?(Regexp)

          SPECIAL_TYPES[t]
        end

        def boolean?
          self[:type] == :boolean || self[:type] == FalseClass || self[:type] == TrueClass
        end

        def serialize?
          self[:serialize] == true
        end

        def component?
          self[:component] == true
        end

        def mutable?
          self[:mutable] == true
        end

        def has_resolver?
          key?(:resolve_with)
        end

        DEFAULT_RESOLUTION_MAP = { Integer => :id }.freeze

        def resolver
          fetch(:resolve_with) { DEFAULT_RESOLUTION_MAP }
        end

        def valid_value?(value)
          type.call(value) || (has_resolver? && resolver.keys.any? { |k| value.is_a?(k) }) || (self[:type] < Entity && value.is_a?(Hash))
        end
      end

      class << self
        def has(name, type = Object, **options)
          attribute = Attribute.new({ entity: self, name: name, type: type, required: true }.merge(options))
          @required_attributes ||= []
          @required_attributes << name if attribute.required?

          if attribute.boolean?
            define_method :"#{name}?" do
              self[name] == true
            end
          end

          if attribute.mutable?
            define_method :"#{name}=" do |value|
              if attribute.type.call(value)
                self[name] = value
              else
                raise TypeError, "#{value.inspect}:#{value.class} is not a valid #{attribute[:type]}"
              end
            end
          end

          if attribute.component? && (mapping = attribute.resolver).is_a?(Hash)
            # type check the attribute name and mapping for security (see class_eval below)
            unless name.is_a?(Symbol) && name.name =~ /\A\w+\z/
              raise TypeError, "Attribute names should be symbols without special characters: #{name.inspect}:#{name.class}"
            end

            mapping.each do |key, value|
              raise TypeError, "Keys in value mappings should be class objects: #{key.inspect}:#{key.class}" unless key.is_a?(Class)
              unless value.is_a?(Symbol) && value.name =~ /\A\w+\z/
                raise TypeError, "Values in value mappings should symbols without special characters: #{value.inspect}:#{value.class}"
              end
            end

            code = <<~CODE
              def #{name}
                value = @hash[#{name.inspect}]
                type  = self.class.attribute(#{name.inspect})[:type]
                if value.is_a?(type)
                  value
                else
                  @hash[#{name.inspect}] = type.ensure!(value)
                end
              end
            CODE

            class_eval code

            case_body = mapping
              .map { |(k, v)|
                "when #{k.name}\n  repository.find_by!(#{v.inspect} => value)" }
              .join("\n")

            attribute[:type].class_eval <<~CODE
              def self.ensure!(value)
                case value
                #{case_body}\n
                when self
                  value
                when Hash
                  new(value)
                else
                  raise TypeError, \"\#{value.inspect}:\#{value.class} cannot be coerced into \#{self}"
                end
              end
            CODE
          else
            define_method name do
              self[name]
            end
          end

          @attributes ||= {}
          @attributes[name] = attribute
        end

        def attributes(regular = true)
          attrs = @attributes && @attributes.values || EMPTY_ARRAY
          if regular && superclass.respond_to?(:attributes)
            (superclass.attributes + attrs).sort_by(&:name)
          else
            attrs
          end
        end

        def attribute(name)
          @attributes.fetch(name)
        end

        def [](attributes = EMPTY_HASH)
          new(attributes)
        end

        def ensure!(value)
          new(value)
        end

        def repository_class_name(class_name = nil)
          @repository_class_name = class_name if class_name
          @repository_class_name || "#{self}Repository"
        end

        def repository_class(klass = nil)
          @repository_class = klass if klass
          return @repository_class if @repository_class

          class_name = repository_class_name
          @repository_class = const_get(class_name) if const_defined?(class_name)
          @repository_class || Repository
        end

        def repository_table_name
          "#{Inflection.plural(Utils.snakecase(self.name.split('::').last))}"
        end

        # When no arguments are given it will return a repository instance. When the class argument
        # is given the value will be used to generate repository instances. When the class_name argument
        # is given the value will be used to fetch the named class as a constant.
        #
        # @example
        #   Product.repository # returns an anonymous repository instance
        #
        # @example
        #   class Product < Entity
        #     repository do
        #       def random
        #         to_a.sample
        #       end
        #     end
        #   end
        #
        #   Product.repository # returns an instance of an anonymous repository subclass with the defined methods
        #
        # @example
        #   class ProductRepository < Repository
        #     def random
        #       to_a.sample
        #     end
        #   end
        #
        #   class Product < Entity
        #   end
        #
        #   Product.repository # returns an instance of ProductRepository
        #
        # @example
        #   class ProductRepo < Repository
        #     def random
        #       to_a.sample
        #     end
        #   end
        #
        #   class Product < Entity
        #     repository class: ProductRepo
        #   end
        #
        #   Product.repository # returns an instance of ProductRepo
        #
        # @example
        #   class Product < Entity
        #     repository class_name: 'ProductRepo'
        #   end
        #
        #   Product.repository # returns and instance of ProductRepo
        #
        # @param options [Hash]
        # @option class_name [String] the name of a user defined subclass of Repository
        # @option class [Class] a user defined subclass of Repository
        # @param block [Proc] a class body for an anonymous Repository subclass
        #
        # @return [Repository]
        def repository(**options, &block)
          if klass = options[:class]
            repository_class(klass)
          elsif class_name = options[:class_name]
            repository_class_name(class_name)
          elsif block
            repository_class Class.new(Repository)
            repository_class.class_eval(&block)
          end

          @repository ||= repository_class.new(App.db[repository_table_name.to_sym], self)
        end

        def valid?(attributes)
          true
        end
      end

      def initialize(attributes = EMPTY_HASH)
        h = {}
        self.class.attributes.each do |attribute|
          default = attribute.default
          name    = attribute.name

          value =
            if default.respond_to?(:call)
              attributes.fetch(name) { default.call }
            else
              attributes.fetch(name) { default }
            end

          next if attribute.optional? && value.nil?

          h[attribute.name] = value

          unless attribute.valid_value?(value)
            raise TypeError, "For #{attribute.entity}##{attribute.name} #{value.inspect}:#{value.class} is not a valid #{attribute[:type]}"
          end
        end

        super(h.freeze)
      end
    end
  end
end
