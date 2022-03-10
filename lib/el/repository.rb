# frozen_string_literal: true

# rubocop disable: Metrics/ClassLength

module El
  # Represents the storage and retrival of a given entity class.
  class Repository
    include Enumerable

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

    def to_s
      "#<#{self.class} entity: #{entity_class}>"
    end
    alias inspect to_s

    private

    def dataset
      @dataset ||= app.database[entity_class.repository_table_name.to_sym]
    end

    def db
      dataset.db
    end

    def collect_fields!
      entity_class
        .attributes
        .reject { |a| entity_class.exclude_for_storage.include?(a.name) }
        .map { |a| Sequel[table_name][a.name] }
    end

    def init_component_fields!
      return if component_attributes.empty?

      data = SqlUtils.component_attribute_query_info(entity_class)
      @fields += data.flat_map { |x| x[:fields] }

      @dataset = data.reduce(@dataset) { |ds, data| ds.join(data[:table], id: data[:ref]) }.select(*fields)
    end

    public

    def table_name
      Utils.table_name(entity_class.canonical_name).to_sym
    end

    def table
      app.database[table_name]
    end

    def empty?
      dataset.empty?
    end

    def all(&block)
      tag = "app.#{table_name}.all"
      logger.info "SQL #{tag}: #{dataset.sql}"

      return to_a unless block

      to_a.each(&block)
    end

    def each(&block)
      return lazy unless block

      dataset.each do |row|
        block&.call(entity(row))
      end

      self
    end

    def pluck(*columns)
      return @simple_dataset.select_map(columns[0]) if columns.size == 1

      @simple_dataset.select_map(columns)
    end

    def find_by(predicates)
      preds = SqlUtils.preprocess_predicates(predicates, table_name)
      logger.info "Query #{entity_class}.repository.find_by: #{preds.inspect}"
      record = dataset.first(preds)
      return nil unless record

      entity(record)
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

        if attr.serialize?
          h.merge!(key => YAML.dump(value))
        else
          h.merge!(key => value)
        end
      end

      @simple_dataset.where(id: id).update(data)
    end

    def valid?(entity, &block)
      validate!(entity)
      block.call(entity_class.new(entity)) if block_given?
      true
    rescue TypeError
      false
    end

    # TODO: add database oriented validations like uniqness here
    def validate!(entity)
      entity_class.validate!(entity)
    end

    def create!(*records)
      if records.size == 1
        return create_each!(records[0]) if records[0].is_a?(Enumerable)

        return create_one!(records[0])
      end

      create_each!(records)
    end

    def create_one!(record)
      validate!(record)
      id = store_one!(entity(record))
      find_by!(id: id)
    end

    def create_each!(records)
      ids = records.map do |record|
        validate!(record)
        store_one!(entity(record))
      end

      where(Sequel[table_name][:id] => ids)
    end

    def store!(*records)
      if records.size == 1
        return store_each!(records[0]) if records[0].is_a?(Enumerable)

        return store_one!(records[0])
      end

      store_each!(records)
    end

    def store_one!(record)
      table.insert(SqlUtils.process_record(entity_class, resolve_entity(record)))
    end

    def store_each!(records)
      db.transaction do
        records.map(&method(:store_entity!))
      end
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

    def find(value)
      return value if value.is_a?(entity_class)
      return entity(value) if value.is_a?(Hash)

      entity_class.reference_mapping.each do |type, ref|
        return find_by(ref => value) if type.call(value)
      end

      nil
    end
    alias [] find
    alias call find

    def to_proc
      ->(value) { find(value) }
    end

    def find!(value)
      find(value) or raise TypeError, "#{value.inspect}:#{value.class} cannot be coerced into #{entity_class}"
    end

    protected

    # delegate logger and db to Mentoring.app
    %i[logger database].each do |method|
      define_method method do
        app.send(method)
      end
    end

    def where(predicates)
      dataset.where(predicates).map(&method(:entity))
    end

    def entity(hash)
      SqlUtils.build_entity(entity_class, hash)
    end

    private

    def resolve_entity(entity)
      data = entity.to_h

      attrs = entity.class.attributes
      attrs.reject { |a| a.default.nil? }.each_with_object(data) do |attr, h|
        h.merge!(attr.name => entity.value_for(attr.name))
      end

      data = data.except(*entity.class.exclude_for_storage)
      attrs.select(&:optional?).each_with_object(data) do |attr, h|
        h.delete(attr.name) if entity.value_for(attr.name).nil?
      end

      comps = entity.class.attributes.select(&:component?)
      return data if comps.empty?

      comps.reduce(data) do |h, comp|
        h.merge!(comp.reference_key => app.ensure_repository!(comp.value_class).find!(entity.value_for(comp.name)).id)
      end
    end
  end
end
