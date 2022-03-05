# frozen_string_literal: true

# rubocop disable: Metrics/ClassLength

module El
  # Represents the storage and retrival of a given entity class.
  class Repository
    include Enumerable

    include Core

    class << self
      def order_by(attribute_name)
        @order_by_attribute_name = attribute_name
      end

      attr_reader :order_by_attribute_name
    end

    attr_reader :app, :entity_class, :fields, :component_attributes

    def initialize(app, entity_class)
      @app = app
      @entity_class = entity_class
      @simple_dataset = dataset

      @component_attributes = @entity_class.component_attributes

      @fields = collect_fields!
      init_component_fields!

      @fields.freeze

      @dataset = @dataset.order(self.class.order_by_attribute_name) if self.class.order_by_attribute_name
    end

    private

    def dataset
      @dataset ||= app.database[entity_class.repository_table_name.to_sym]
    end

    def db
      dataset.db
    end

    def collect_fields!
      entity_class.attributes
                  .reject { |a| entity_class.exclude_for_storage.include?(a.name) }
                  .map { |a| Sequel[table_name][a.name] }
    end

    def init_component_fields!
      return if component_attributes.empty?

      data = SqlUtils.component_attribute_query_info(entity_class)
      @fields += data.flat_map { |x| x[:fields] }

      @dataset = data.reduce(@dataset) { |ds, data| ds.join(data[:table], id: data[:ref]) }
                     .select(*fields)
    end

    public

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
      preds = SqlUtils.preprocess_predicates(predicates, table_name)
      logger.info "Query #{entity_class}.repository.find_by: #{preds.inspect}"
      record = dataset.first(preds)
      return nil unless record

      SqlUtils.build_entity(entity_class, record)
    end

    def find_by!(attributes)
      find_by(attributes) or raise "Could not find record with: #{attributes.inspect}"
    end

    def update!(id, updates)
      data = updates.each_with_object({}) do |(key, value), h|
        attr = entity_class.attribute(key)
        next if attr.nil? || (value.nil? && attr.optional?)

        unless attr.valid_value?(value)
          raise TypeError, "For #{entity_class}##{key} #{value.inspect}:#{value.class} is not a valid #{attr[:type]}"
        end

        if attr.component?
          h[attr.reference_key] = value.fetch(:id)
          next
        end

        h[key] =
          if attr.serialize?
            YAML.dump(value)
          else
            value
          end
      end

      logger.info "UPDATE: #{data.inspect}"

      @simple_dataset.where(id: id).update(data)
    end

    def create!(record)
      id = store!(record)
      find_by!(id: id)
    end

    def store!(*args)
      if args.length == 0
        return store_all!(args[0]) if args[0].is_a?(Array)

        return store_entity!(args[0])
      end

      store_all!(args)
    end

    def store_entity!(record)
      table.insert(SqlUtils.process_record(entity_class, resolve_entity(record)))
    end

    def store_all!(records)
      table.multi_insert(records.map { |r| SqlUtils.process_record(entity_class, resolve_entity(r)) })
    end

    def delete_where!(predicates)
      @simple_dataset.where(predicates).delete
    end

    def delete_all!
      table.delete
    end

    def ensure!(value)
      case value
      when entity_class
        value
      when Hash
        new(value)
      else
        logger.info "#{entity_class}.reference_mapping #{entity_class.reference_mapping.inspect}"
        # NOTE: As an optimization we could generate the comparible code
        # whenever a reference attribute is added to the class.
        entity_class.reference_mapping.each do |type, ref|
          logger.info "#{entity_class}.repository.find_by(#{ref.inspect} => #{value.inspect})"
          return find_by!(ref => value) if type.call(value)
        end

        raise TypeError, "#{value.inspect}:#{value.class} cannot be coerced into #{entity_class}"
      end
    end
    alias [] ensure!

    def resolve_entity(entity)
      data = entity.to_h

      attrs = entity.class.attributes
      attrs.reject { |a| a.default.nil? }.each { |attr| data[attr.name] = entity.value_for(attr.name) }

      data = data.except(*entity.class.exclude_for_storage)
      attrs
        .select(&:optional?)
        .each { |attr| data.delete(attr.name) if entity.value_for(attr.name).nil? }

      if (comps = entity.class.attributes.select(&:component?)).empty?
        data
      else
        comps.reduce(data) do |h, comp|
          logger.info "comp: #{comp.value_class.inspect}"
          h.merge!(comp.reference_key => app.ensure_repository!(comp.value_class).ensure!(entity.value_for(comp.name)).id)
        end
      end
    end

    protected

    def where(predicates)
      dataset.where(predicates).map do |row|
        SqlUtils.build_entity(entity_class, row)
      end
    end

    def build_entity(hash)
      SqlUtils.build_entity(entity_class, hash)
    end

    private

    # delegate logger and db to Mentoring.app
    %i[logger database].each do |method|
      define_method method do
        app.send(method)
      end
    end
  end
end
