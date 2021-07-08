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
        sql =
          SqlUtils.query_template(
            entity_class,
            db,
            one: false,
            predicates: false,
            order_by: self.class.order_by_attribute_name
          )

        run sql, tag: tag do |records|
          records.map { |record| build_entity(record).tap { |product| block&.call(product) } }
        end
      end
      alias each all

      def find_by(predicates)
        preds = predicates.transform_keys(&SqlUtils.query_attribute_map(entity_class))
        qstr, binds = SqlUtils.where(db, preds)
        query =
          SqlUtils
            .query_template(entity_class, db, one: true, predicates: true)
            .sub('/* where */', qstr)

        records = run(query, *binds, tag: "#{entity_class}.repository.find_by")

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
        qstr, binds = SqlUtils.where(db, predicates)
        table = entity_class.repository_table_name
        query = "delete from #{db.literal(Sequel.identifier(table))} #{qstr}"

        run query, *binds, tag: 'delete_where!'

        self
      end

      def delete_all!
        dataset.delete
      end

      private

      %i[logger db].each do |method|
        define_method method do
          Drn::Mentoring.app.send(method)
        end
      end

      protected

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
          .each { |attr| h.merge!(attr.name => YAML.dump(h[attr.name])) if h[attr.name] }

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
          .each { |attr| h = h.merge(attr.name => YAML.load(h[attr.name])) if h[attr.name] }
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
