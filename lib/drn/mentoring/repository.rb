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
          data =
            @component_attributes.map do |attr|
              table = attr.component_table_name.to_sym
              fields =
                attr
                  .value_class
                  .attributes
                  .map { |attr1| Sequel[table][attr1.name].as(:"#{attr.name}_#{attr1.name}") }

              [fields, table, attr.reference_key]
            end

          @fields += data.flat_map(&:first)

          @dataset =
            data.reduce(@dataset) { |ds, (_, table, ref)| ds.join(table, id: ref) }.select(*fields)
        end

        @fields.freeze
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
        sql =
          SqlUtils.query_template(
            entity_class,
            db,
            one: false,
            predicates: false,
            order_by: self.class.order_by_attribute_name
          )

        SqlUtils.run sql, tag: tag do |records|
          records.map do |record|
            SqlUtils.build_entity(entity_class, record).tap { |product| block&.call(product) }
          end
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

        records = SqlUtils.run(query, *binds, tag: "#{entity_class}.repository.find_by")

        return nil if records.empty?

        SqlUtils.build_entity(entity_class, records.first)
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
