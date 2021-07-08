module Drn
  module Mentoring
    module SqlUtils
      module_function

      def ident_quote(db, *args)
        case args.size
        when 1
          db.literal(Sequel.identifier(args[0]))
        when 2
          db.literal(Sequel.qualify(*args))
        else
          raise ArgumentError, "wrong number or arguments (given #{args.size}, expected 1 or 2)"
        end
      end

      ATTRIBUTE_MAP = Hash.new { |_, key| key }

      def query_attribute_map(entity_class)
        entity_class
          .attributes
          .each_with_object(ATTRIBUTE_MAP.dup) do |attr, hash|
            attr_name = attr.component? ? attr.reference_key : attr.name
            if attr.many?
              hash
            else
              hash.merge!(
                attr.name => Sequel.qualify(entity_class.repository_table_name, attr_name)
              )
            end
          end
      end

      def query_fields(entity_class, db)
        fields =
          query_attribute_map(entity_class)
            .reject { |(name, _)| entity_class.exclude_for_storage.include?(name) }
            .map { |(_, ident)| db.literal(ident) }

        entity_class.component_attributes.each_with_index do |comp, i|
          comp
            .value_class
            .storable_attributes
            .each do |attr|
              table = "#{entity_class.component_table_name(comp)}#{i}"
              ident = Sequel.qualify(table, attr.name)
              name = Sequel.identifier("#{comp.name}_#{attr.name}")
              fields << "#{db.literal(ident)} as #{db.literal(name)}"
            end
        end

        fields.join(', ')
      end

      def query_template(entity_class, db, one:, predicates:, order_by: nil)
        buffer = StringIO.new

        buffer.write 'select '
        buffer.write query_fields(entity_class, db)
        buffer.write ' from '
        buffer.write entity_class.repository_table_name

        entity_class.component_attributes.each_with_index do |attr, i|
          component_table_name = entity_class.component_table_name(attr)
          component_table_alias = "#{component_table_name}#{i}"
          buffer.write " inner join #{ident_quote(db, component_table_name)}"
          buffer.write " as #{ident_quote(db, component_table_alias)}"
          buffer.write ' on '
          buffer.write ident_quote(db, entity_class.repository_table_name, attr.reference_key)
          buffer.write ' = '
          buffer.write ident_quote(db, component_table_alias, 'id')
        end

        buffer.write(' /* where */') if predicates
        buffer.write(" order by #{ident_quote(db, order_by)}") if one == false && order_by
        buffer.write(' limit 1') if one

        buffer.string
      end

      def where(db, predicates)
        preds = predicates.map { |(ident, _)| "#{db.literal(ident)} = ?" }

        ["where #{preds.join(' and ')}", predicates.values]
      end
    end
  end
end
