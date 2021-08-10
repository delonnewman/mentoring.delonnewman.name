# frozen_string_literal: true

module Drn
  module Framework
    require_relative 'entity/attribute'
    require_relative 'entity/associations'
    require_relative 'entity/repositories'
    require_relative 'entity/validation'
    require_relative 'entity/types'

    # Represents a domain entity that will be modeled. Provides dynamic checks and
    # meta objects for relfection which is used to drive productivity and inspection tools.
    class Entity < HashDelegator
      transform_keys(&:to_sym)

      extend Core
      include Core
      extend Forwardable
      extend Associations
      extend Repositories
      extend Validation
      extend Types

      class << self
        @@app = nil

        def inherited(klass)
          return if klass.name.nil? || @@app.nil?

          method_name = Utils.plural(klass.name)

          app.define_singleton_method method_name do
            klass.repository
          end

          class_name = klass.name.split('::').last
          app.define_singleton_method class_name do
            klass
          end
        end

        def has(name, type = Object, **options)
          attribute =
            Attribute.new({ entity: self, name: name, type: type, required: true }.merge(options))
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
                raise TypeError,
                      "#{value.inspect}:#{value.class} is not a valid #{attribute[:type]}"
              end
            end
          end

          if attribute.component? && (mapping = attribute.resolver).is_a?(Hash)
            # type check the attribute name and mapping for security (see class_eval below)
            unless name.is_a?(Symbol) && name.name =~ /\A\w+\z/
              raise TypeError,
                    "Attribute names should be symbols without special characters: #{name.inspect}:#{name.class}"
            end

            mapping.each do |key, value|
              unless key.respond_to?(:call)
                raise TypeError,
                      "Keys in value mappings should be callable objects: #{key.inspect}:#{key.class}"
              end
              unless value.is_a?(Symbol) && value.name =~ /\A\w+\z/
                raise TypeError,
                      "Values in value mappings should symbols without special characters: #{value.inspect}:#{value.class}"
              end
            end

            define_method name do
              value = @hash[name]
              type = self.class.attribute(name).value_class
              if value.is_a?(type)
                value
              else
                @hash[name.inspect] = type.ensure!(value)
              end
            end
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

          name
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
        alias call []

        def to_proc
          lambda { |attributes| call(attributes) }
        end

        def canonical_name
          Utils.snakecase(name.split('::').last)
        end
      end

      def initialize(attributes = EMPTY_HASH)
        h = {}
        attrs = self.class.attributes

        attrs.each do |attribute|
          name = attribute.name
          value = attributes[name]

          h[attribute.name] = value

          next if (attribute.optional? && value.nil?) || !attribute.default.nil?

          unless attribute.valid_value?(value)
            raise TypeError,
                  "For #{attribute.entity}##{attribute.name} #{value.inspect}:#{value.class} is not a valid #{attribute[:type]}"
          end
        end

        super(h.freeze)
      end

      def value_for(name)
        return self[name] if self[name]

        default = self.class.attribute(name).default

        @hash[name] ||= default.is_a?(Proc) ? instance_exec(&default) : default
      end

      def to_h
        data = super

        attrs = self.class.attributes
        attrs.reject { |a| a.default.nil? }.each { |attr| data[attr.name] = value_for(attr.name) }

        data = data.except(*self.class.exclude_for_storage)
        attrs
          .select(&:optional?)
          .each { |attr| data.delete(attr.name) if value_for(attr.name).nil? }

        if (comps = self.class.attributes.select(&:component?)).empty?
          data
        else
          comps.reduce(data) { |h, comp| h.merge!(comp.reference_key => send(comp.name).id) }
        end
      end
    end
  end
end
