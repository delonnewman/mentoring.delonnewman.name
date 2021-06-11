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
        @dataset      = dataset
        @db           = dataset.db
        @entity_class = entity_class
      end

      def empty?
        first.nil?
      end

      def all(&block)
        run sql_query_template(one: false) do |records|
          records.map do |record|
            build_entity(record).tap do |product|
              block&.call(product)
            end
          end
        end
      end
      alias each all

      def find_by(predicates)
        preds       = predicates.transform_keys(&query_attribute_map)
        qstr, binds = sql_where(preds)
        query       = sql_query_template(one: true).sub('/* where */', qstr)
        records     = run(query, *binds)

        return nil if records.empty?

        build_entity(records.first)
      end

      def find_by!(attributes)
        find_by(attributes) or raise "Could not find record with: #{attributes.inspect}"
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
        query       = "delete from products #{qstr}"
        run(query, *binds)
        self
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
        entity_class.attributes.each_with_object(ATTRIBUTE_MAP.dup) do |attr, hash|
          attr_name = attr.component? ? attr.reference_key : attr.name
          if attr.many?
            hash
          else
            hash.merge!(attr.name => Sequel.qualify(entity_class.repository_table_name, attr_name))
          end
        end
      end

      def sql_query_template(one:)
        buffer = StringIO.new

        buffer.write 'select '
        buffer.write query_attribute_map.values.map { |ident| db.literal(ident) }.join(', ')
        buffer.write ' from '
        buffer.write entity_class.repository_table_name

        entity_class.attributes.each do |attr|
          next unless attr.component?

          component_table_name = entity_class.component_table_name(attr.name)
          buffer.write " inner join #{db.literal(Sequel.identifier(component_table_name))} on "
          buffer.write ' '
          buffer.write db.literal(Sequel.qualify(entity_class.repository_table_name, attr.reference_key))
          buffer.write ' = '
          buffer.write db.literal(Sequel.qualify(component_table_name, 'id'))
        end

        buffer.write(' /* where */')

        order_by = self.class.order_by_attribute_name
        buffer.write(" order by #{Sequel.identifier(order_by)}") if one == false && order_by

        buffer.write(' limit 1') if one

        buffer.string
      end

      def sql_where(predicates)
        preds = predicates.map do |(ident, _)|
          "#{db.literal(ident)} = ?"
        end

        ["where #{preds.join(' and ')}", predicates.values]
      end

      def nest_component_attributes(record, component_name)
        record.reduce({}) do |h, (key, value)|
          key = key.is_a?(Symbol) ? key.name : key
          if key.start_with?(component_name)
            h[component_name.to_sym] ||= {}
            k = key.name.sub("#{component_name}_", '').to_sym
            h[component_name.to_sym][k] = value
          else
            h[key] = value
          end
          h
        end
      end

      def run(query, *args, entity_class: nil, tag: nil, &block)
        tag = tag ? 'SQL' : "SQL #{tag}"
        logger.info "#{tag}: #{query.gsub(/\s+/, ' ')}, args: #{args.inspect}"

        results = []
        @dataset.db.fetch(query, *args) do |row|
          row = row.transform_keys(&:to_sym)
          if entity_class
            results << entity_class[row]
          else
            results << row
          end
        end

        return EMPTY_ARRAY if results.empty?

        if block
          block.call(results)
        else
          results
        end
      end

      # TODO: for performance this would be better as opt-in
      def process_record(record)
        record = entity_class.ensure!(record)
        h = record.to_h.dup
        record.class.attributes.select(&:serialize?).each do |attr|
          h.merge!(attr.name => YAML.dump(h[attr.name])) if h[attr.name]
        end

        record.class.attributes.select(&:component?).each do |attr|
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
        entity_class.attributes.select(&:serialize?).each do |attr|
          h = h.merge(attr.name => YAML.load(h[attr.name])) if h[attr.name]
        end
        h
      end

      def build_entity(record)
        record = reconstitute_record(record)
        entity_class.attributes.select(&:component?).each do |attr|
          record = nest_component_attributes(record, attr.name)
        end

        entity_class[record]
      end
    end
  end
end
