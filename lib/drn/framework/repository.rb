# frozen_string_literal: true

module Drn
  module Framework
    # Represents the storage and retrival of a given entity class.
    class Repository
      include Enumerable

      include Core

      class << self
        def order_by(attribute_name)
          @order_by_attribute_name = attribute_name
        end

        def order_by_attribute_name
          @order_by_attribute_name
        end
      end

      attr_reader :entity_class, :dataset, :fields, :db, :component_attributes

      def initialize(dataset, entity_class)
        @entity_class = entity_class
        @db = dataset.db

        @component_attributes = @entity_class.component_attributes

        @fields =
          entity_class
            .attributes
            .reject { |a| entity_class.exclude_for_storage.include?(a.name) }
            .map { |a| Sequel[table_name][a.name] }

        @dataset = dataset

        unless @component_attributes.empty?
          data = SqlUtils.component_attribute_query_info(entity_class)
          @fields += data.flat_map { |x| x[:fields] }

          @dataset =
            data.reduce(@dataset) { |ds, data| ds.join(data[:table], id: data[:ref]) }.select(*fields)

        end

        @fields.freeze

        @dataset = @dataset.order(self.class.order_by_attribute_name) if self.class.order_by_attribute_name
      end

      def table_name
        Utils.table_name(entity_class.canonical_name).to_sym
      end

      def table
        db[table_name]
      end

      def empty?
        first.nil?
      end

      def all(&block)
        tag = "#{entity_class}.repository.all"
        logger.info "SQL #{tag}: #{dataset.sql}"

        dataset.each do |row|
          entity = SqlUtils.build_entity(entity_class, row)
          block&.call(entity)
        end
      end
      alias each all

      def find_by(predicates)
        record = dataset.first(SqlUtils.preprocess_predicates(predicates, table_name))
        return nil unless record

        SqlUtils.build_entity(entity_class, record)
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
        table.insert(SqlUtils.process_record(entity_class, record))

        self
      end

      def store_all!(records)
        table.multi_insert(records.map(&SqlUtils.method(:process_record).curry[entity_class]))

        self
      end

      def delete_where!(predicates)
        qstr, binds = SqlUtils.where(db, predicates)
        query = "delete from #{db.literal(Sequel.identifier(table_name))} #{qstr}"

        SqlUtils.run query, *binds, tag: 'delete_where!'

        self
      end

      def delete_all!
        table.delete
      end

      private

      # delegate logger and db to Drn::Mentoring.app
      %i[logger db].each do |method|
        define_method method do
          Drn::Mentoring.app.send(method)
        end
      end
    end
  end
end