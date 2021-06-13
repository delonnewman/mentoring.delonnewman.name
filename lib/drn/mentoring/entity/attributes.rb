module Drn
  module Mentoring
    class Entity
      # Represents an attribute of a domain entity. Drives dynamic checks and provides
      # meta objects for reflection.
      class Attribute < HashDelegator
        require :entity, :name, :required, :type

        def required?
          self[:required] == true
        end

        DEFAULT_DISPLAY_ORDER = 99

        def display_order
          d = self[:display]
          return DEFAULT_DISPLAY_ORDER if d == true
          return DEFAULT_DISPLAY_ORDER unless d

          d.fetch(:order) { DEFAULT_DISPLAY_ORDER }
        end

        def display_name
          d = self[:display]
          return Utils.titlecase(name) if d == true
          return Utils.titlecase(name) unless d

          d.fetch(:name) { Utils.titlecase(name.capitalize) }
        end

        def time?
          self[:type].is_a?(Class) && (self[:type] == Time || self[:type] < Time)
        end

        def password?
          self[:type] == :password
        end

        def email?
          self[:type] == :email
        end

        def optional?
          !required?
        end

        def default
          self[:default]
        end

        def type
          t = self[:type]

          return t                           if t.respond_to?(:call)
          return CLASSICAL_TYPE[t]           if t.is_a?(Class)
          return CLASSICAL_TYPE[value_class] if t.is_a?(String)
          return REGEXP_TYPE[t]              if t.is_a?(Regexp)

          SPECIAL_TYPES[t]
        end

        def value_class
          t = self[:type]
          return t if t.is_a?(Class)
          return Utils.constantize(t) if t.is_a?(String)
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

        def many?
          self[:many] == true
        end

        def mutable?
          self[:mutable] == true
        end

        def resolver
          value_class&.reference_mapping
        end

        def valid_reference?(value)
          return false unless entity?
          return true  if value.is_a?(Hash) # TODO: use the value class to validate

          mapping = value_class.reference_mapping
          mapping.keys.any? { |k| value.is_a?(k) }
        end

        def entity?
          klass = value_class
          klass && klass < Entity
        end

        def valid_value?(value)
          type.call(value) || valid_reference?(value)
        end
      end
    end
  end
end
