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
      EMAIL_REGEXP   = /\A[a-zA-Z0-9!#\$%&'*+\/=?\^_`{|}~\-]+(?:\.[a-zA-Z0-9!#\$%&'\*+\/=?\^_`{|}~\-]+)*@(?:[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?$\z/.freeze

      SPECIAL_TYPES = {
        boolean: ->(v) { v.is_a?(FalseClass) || v.is_a?(TrueClass) },
        string:  CLASSICAL_TYPE[String],
        any:     CLASSICAL_TYPE[BasicObject],
        uuid:    REGEXP_TYPE[UUID_REGEXP],
        email:   REGEXP_TYPE[EMAIL_REGEXP]
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

        def reference_key
          :"#{name}_id"
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

        def type_entity?
          self[:type].is_a?(Class) && self[:type] < Entity
        end

        def valid_value?(value)
          type.call(value) || (has_resolver? && resolver.keys.any? { |k| value.is_a?(k) }) || (type_entity? && value.is_a?(Hash))
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
          elsif attribute.default
            define_method name do
              value_for(name)
            end
          else
            define_method name do
              self[name]
            end
          end

          @attributes ||= {}
          @attributes[name] = attribute
        end

        def primary_key(name = :id, type = Integer, **options)
          opts = options.merge(required: false, unique: true, index: true, primary_key: true)
          if type == :uuid
            opts[:default] = ->{ SecureRandom.uuid }
            opts[:required] = true
          end
          reference name, type, **opts
        end

        def reference(name, type, **options)
          has name, type, **options.merge(reference: true)
        end

        def reference_mapping
          attributes
            .select { |a| a[:reference] }
            .reduce({}) { |h, a| h.merge(a[:type] => a.name) }
        end

        def belongs_to(name, entity_class, **options)
          has name, entity_class, **options.merge(resolve_with: entity_class.reference_mapping, component: true)
          exclude_for_storage << name
        end

        def timestamps
          has :created_at, Time, default: ->{ Time.now }
          has :updated_at, Time, default: ->{ Time.now }
        end

        def exclude_for_storage
          @exclude_for_storage ||= []
        end

        def password
          has :encrypted_password, required: false, default: ->{ BCrypt::Password.create(password) }
          has :password,           required: false, default: ->{ BCrypt::Password.new(encrypted_password) }
          exclude_for_storage << :password
        end

        def email(name = :email, **options)
          has name, :email, **options
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

        def valid?(entity)
          return false if entity.empty?
          
          attributes.reduce(true) do |is_valid, attr|
            is_valid && attr.required? && !!(value = entity[attr.name]) && attr.valid_value?(value) && !attr.default
          end
        end

        # TODO: move this to a validator or form object similar in function to repository
        def errors(entity)
          attributes.reduce({}) do |errors, attr|
            key  = attr.name
            name = key.to_s.tr('_', ' ').capitalize

            a = []

            if attr.required? && (value = entity[key]).blank? && !attr.default
              a << attr.fetch(:message) { "#{name} is required" }
            end

            if value && !attr.valid_value?(value)
              a << attr.fetch(:message) { "#{name} is not valid" }
            end

            unique = attr[:unique]
            repo   = if unique.is_a?(Class) && unique < Entity
                       unique.repository
                     elsif unique.is_a?(Repository)
                       unique
                     else
                       repository
                     end

            if unique && repo.find_by(attr.name => value)
              a << attr.fetch(:message) { "#{name} is not unique" }
            end
            
            if a.empty?
              errors
            else
              errors.merge!(key => a)
            end
          end
        end

        def [](attributes = EMPTY_HASH)
          new(attributes)
        end

        def ensure!(value)
          return value if value.is_a?(self)

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

          @repository ||= repository_class.new(Drn::Mentoring.app.db[repository_table_name.to_sym], self)
        end
      end

      def initialize(attributes = EMPTY_HASH)
        h = {}
        self.class.attributes.each do |attribute|
          name    = attribute.name
          value   = attributes[name]

          h[attribute.name] = value

          next if (attribute.optional? && value.nil?) || attribute.default

          unless attribute.valid_value?(value)
            raise TypeError, "For #{attribute.entity}##{attribute.name} #{value.inspect}:#{value.class} is not a valid #{attribute[:type]}"
          end
        end

        super(h.freeze)
      end

      def value_for(name)
        return self[name] if self[name]

        default = self.class.attribute(name).default
        if default.respond_to?(:to_proc)
          @hash[name] ||= instance_exec(&default)
        else
          @hash[name] ||= default
        end
      end

      def to_h
        data = super

        self.class.attributes.select(&:default).each do |attr|
          data[attr.name] = value_for(attr.name)
        end
        
        data = data.except(*self.class.exclude_for_storage)

        self.class.attributes.select(&:optional?).each do |attr|
          if (val = value_for(attr.name)).nil?
            data.delete(attr.name)
          end
        end

        if (comps = self.class.attributes.select(&:component?)).empty?
          data
        else
          comps.reduce(data) do |h, comp|
            h.merge!(comp.reference_key => send(comp.name).id)
          end
        end
      end
    end
  end
end
