# frozen_string_literal: true

module Drn
  module Mentoring
    # Represents the storage and retrival of a given entity class.
    class Repository
      include Enumerable

      class << self
        def order_by(attribute_name)
          @order_by_attribute_name = attribute_name
        end

        def order_by_attribute_name
          @order_by_attribute_name
        end
      end

      attr_reader :entity_class, :dataset, :db

      def initialize(dataset, entity_class)
        @dataset = dataset
        @db = dataset.db
        @entity_class = entity_class
      end

      def empty?
        first.nil?
      end

      def all(&block)
        tag = "#{entity_class}.repository.all"
        run sql_query_template(one: false, predicates: false),
            tag: tag do |records|
          records.map do |record|
            build_entity(record).tap { |product| block&.call(product) }
          end
        end
      end
      alias each all

      def find_by(predicates)
        preds = predicates.transform_keys(&query_attribute_map)
        qstr, binds = sql_where(preds)
        query =
          sql_query_template(one: true, predicates: true).sub(
            '/* where */',
            qstr
          )
        records = run(query, *binds, tag: "#{entity_class}.repository.find_by")

        return nil if records.empty?

        build_entity(records.first)
      end

      def find_by!(attributes)
        find_by(attributes) or
          raise "Could not find record with: #{attributes.inspect}"
      end

      def update!(id, data)
        dataset.where(id: id).update(data)
        find_by!(id: id)
      end

      def create!(record)
        store!(record)
        entity_class[record]
      end

      def store!(record)
        dataset.insert(process_record(record))
        self
      end

      def store_all!(records)
        dataset.multi_insert(records.map(&method(:process_record)))
        self
      end

      def delete_where!(predicates)
        qstr, binds = sql_where(predicates)
        table = entity_class.repository_table_name
        query = "delete from #{db.literal(Sequel.identifier(table))} #{qstr}"

        run(query, *binds, tag: 'delete_where!')

        self
      end

      def delete_all!
        dataset.delete
      end

      protected

      %i[logger db].each do |method|
        define_method method do
          Drn::Mentoring.app.send(method)
        end
        private method
      end

      ATTRIBUTE_MAP = Hash.new { |_, key| key }

      def query_attribute_map
        entity_class
          .attributes
          .each_with_object(ATTRIBUTE_MAP.dup) do |attr, hash|
            attr_name = attr.component? ? attr.reference_key : attr.name
            if attr.many?
              hash
            else
              hash.merge!(
                attr.name =>
                  Sequel.qualify(entity_class.repository_table_name, attr_name)
              )
            end
          end
      end

      def sql_query_fields
        fields =
          query_attribute_map
            .reject do |(name, _)|
              entity_class.exclude_for_storage.include?(name)
            end
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

      def sql_ident_quote(*args)
        if args.size == 1
          db.literal(Sequel.identifier(args[0]))
        elsif args.size == 2
          db.literal(Sequel.qualify(*args))
        else
          raise ArgumentError,
                "wrong number or arguments (given #{args.size}, expected 1 or 2)"
        end
      end

      def sql_query_template(one:, predicates:)
        buffer = StringIO.new

        buffer.write 'select '
        buffer.write sql_query_fields
        buffer.write ' from '
        buffer.write entity_class.repository_table_name

        entity_class.component_attributes.each_with_index do |attr, i|
          component_table_name = entity_class.component_table_name(attr)
          component_table_alias = "#{component_table_name}#{i}"
          buffer.write " inner join #{sql_ident_quote(component_table_name)}"
          buffer.write " as #{sql_ident_quote(component_table_alias)}"
          buffer.write ' on '
          buffer.write sql_ident_quote(
                         entity_class.repository_table_name,
                         attr.reference_key
                       )
          buffer.write ' = '
          buffer.write sql_ident_quote(component_table_alias, 'id')
        end

        buffer.write(' /* where */') if predicates

        order_by = self.class.order_by_attribute_name
        if one == false && order_by
          buffer.write(" order by #{sql_ident_quote(order_by)}")
        end

        buffer.write(' limit 1') if one

        buffer.string
      end

      def sql_where(predicates)
        preds = predicates.map { |(ident, _)| "#{db.literal(ident)} = ?" }

        ["where #{preds.join(' and ')}", predicates.values]
      end

      def nest_component_attributes(record, component_name)
        record.reduce({}) do |h, (key_, value)|
          key = key_.is_a?(Symbol) ? key_.name : key_
          if key.start_with?(component_name.name)
            h[component_name.to_sym] ||= {}
            k = key.sub("#{component_name}_", '').to_sym
            h[component_name.to_sym][k] = value
          else
            h[key_] = value
          end
          h
        end
      end

      def run(query, *args, tag: nil, &block)
        tag = tag.nil? ? 'SQL' : "SQL #{tag}"
        logger.info "#{tag}: #{query.gsub(/\s+/, ' ')}, args: #{args.inspect}"

        results = []
        @dataset
          .db
          .fetch(query, *args) do |row|
            row = row.transform_keys(&:to_sym)
            results << row
          end

        return EMPTY_ARRAY if results.empty?

        block ? block.call(results) : results
      end

      # TODO: for performance this would be better as opt-in
      def process_record(record)
        record = entity_class.ensure!(record)
        h = record.to_h.dup
        record
          .class
          .attributes
          .select(&:serialize?)
          .each do |attr|
            h.merge!(attr.name => YAML.dump(h[attr.name])) if h[attr.name]
          end

        record
          .class
          .attributes
          .select(&:component?)
          .each do |attr|
            id_key = attr.reference_key
            if !record.key?(id_key) && (id_val = record.send(attr.name).id)
              h[id_key] = id_val
            elsif attr.required?
              raise "#{id_key.inspect} is required for storage but is missing"
            end
            h.delete(attr.name)
          end

        h[:updated_at] = Time.now if h.key?(:updated_at)

        h
      end

      def reconstitute_record(h)
        entity_class
          .attributes
          .select(&:serialize?)
          .each do |attr|
            h = h.merge(attr.name => YAML.load(h[attr.name])) if h[attr.name]
          end
        h
      end

      def build_entity(record)
        record = reconstitute_record(record)
        entity_class
          .attributes
          .select(&:component?)
          .each do |attr|
            begin
              record = nest_component_attributes(record, attr.name)
            rescue StandardError
              binding.irb
            end
          end

        entity_class[record]
      end
    end
  end
end
