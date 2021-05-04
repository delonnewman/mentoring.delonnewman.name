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
        include Comparable
        require :name, :required, :type

        def required?
          self[:required] == true
        end

        def type
          t = self[:type]

          return t                 if t.respond_to?(:call)
          return CLASSICAL_TYPE[t] if t.is_a?(Class)
          return REGEXP_TYPE[t]    if t.is_a?(RegExp)

          SPECIAL_TYPES[t]
        end

        def boolean?
          self[:type] == :boolean || self[:type] == FalseClass || self[:type] == TrueClass
        end

        def mutable?
          self[:mutable] == true
        end

        def <=>(other)
          name <=> other.name
        end
      end

      class << self
        def has(name, type = Object, **options)
          attribute = Attribute.new({ name: name, type: type, required: true }.merge(options))
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

          if attribute.respond_to?(:default)
            default = attribute.default
            if default.respond_to?(:to_proc)
              define_method name do
                fetch(name, &default)
              end
            else
              define_method name do
                fetch(name) { default }
              end
            end
          end

          @attributes ||= {}
          @attributes[name] = attribute
        end

        def attributes(regular = true)
          if regular && superclass.respond_to?(:attributes)
            (superclass.attributes + @attributes.values).sort_by(&:name)
          else
            @attributes.values
          end
        end

        def attribute(name)
          @attributes.fetch(name)
        end

        def [](attributes = EMPTY_HASH)
          new(attributes)
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
          "#{Inflection.plural(self.name.split('::').last.downcase)}"
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
        super(attributes)

        self.class.attributes.each do |attribute|
          value   = attributes[attribute.name]
          if attribute.type.call(value)
            raise TypeError, "#{value.inspect}:#{value.class} is not a valid #{attribute[:type]}"
          end
        end
      end
    end
  end
end
