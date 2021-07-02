module Drn
  module Mentoring
    class Entity
      # Methods used for Entity associations
      module Associations
        def reference_key
          :"#{canonical_name.downcase}_id"
        end

        def has_many(name, **options)
          type = Utils.entity_name(name)
          has name,
              type,
              **{ required: false }.merge!(options.merge(many: true))

          define_method name do
            if self[name]
              self[name]
            else
              attr = self.class.attribute(name)
              self[name] =
                attr.join_table.where(attr.entity.reference_key => id)
            end
          end

          exclude_for_storage << name
          name
        end

        def belongs_to(name, **options)
          type = Utils.entity_name("#{self}_#{name}")
          has name, type, **options.merge(component: true)
          exclude_for_storage << name
          name
        end

        def component_table_name(attribute)
          Utils.table_name(attribute.value_class.canonical_name)
        end

        def component_attributes
          attributes.select(&:component?)
        end

        def reference(name, type, **options)
          has name, type, **options.merge(reference: true)
        end

        def reference_mapping
          attributes
            .select { |a| a[:reference] }
            .reduce({}) { |h, a| h.merge(a[:type] => a.name) }
        end

        def primary_key(name = :id, type = Integer, **options)
          opts = {
            required: false,
            unique: true,
            index: true,
            primary_key: true,
            display: false,
            edit: false
          }

          opts.merge!(options)

          if type == :uuid
            opts[:default] = -> { SecureRandom.uuid }
            opts[:required] = true
          end

          reference name, type, **opts
        end

        def ensure!(value)
          case value
          when self
            value
          when Hash
            new(value)
          else
            # NOTE: As an optimization we could generate the comparible code
            # whenever a reference attribute is added to the class.
            reference_mapping.each do |klass, ref|
              return repository.find_by!(ref => value) if value.is_a?(klass)
            end
            raise TypeError,
                  "#{value.inspect}:#{value.class} cannot be coerced into #{self}"
          end
        end

        def exclude_for_storage
          @exclude_for_storage ||= Set.new
        end

        def storable_attributes
          attributes.reject { |attr| exclude_for_storage.include?(attr.name) }
        end
      end
    end
  end
end
