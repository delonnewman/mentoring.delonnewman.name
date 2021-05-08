module Drn
  module Mentoring
    class Repository
      include Enumerable

      def initialize(dataset, factory)
        @dataset = dataset
        @factory = factory
      end

      def empty?
        first.nil?
      end

      def each(&block)
        @dataset.each do |row|
          block.call(@factory[row])
        end
        self
      end

      def find_by(attributes)
        record = @dataset.first(attributes)
        return nil unless record
        @factory[record]
      end

      def find_by!(attributes)
        find_by(attributes) or raise "Could not find record with: #{attributes.inspect}" 
      end

      def store!(record)
        @dataset.insert(record.to_h)
        self
      end

      def store_all!(records)
        @dataset.multi_insert(records.map(&:to_h))
        self
      end
  
      protected

      attr_reader :dataset, :factory

      %i[logger db].each do |method|
        define_method method do
          App.send(method)
        end
        private method
      end

      def sql_where(predicates)
        preds = predicates.map do |(key, value)|
          kstr = Symbol ? key.name : key.to_s

          k = 
            if not kstr.include?('.')
              Sequel.identifier(kstr)
            else
              kstr.split('.').reduce do |a, b|
                if a.respond_to?(:qualify)
                  a.qualify(b)
                else
                  Sequel.qualify(a, b)
                end
              end
            end

          "#{db.literal(k)} = ?"
        end

        ["where #{preds.join(' and ')}", predicates.values]
      end

      def nest_component_attributes(record, component_name)
        record.reduce({}) do |h, (key, value)|
          if key.start_with?(component_name)
            h[:role] ||= {}
            k = key.name.sub("#{component_name}_", '').to_sym
            h[:role][k] = value
          else
            h[key] = value
          end
          h
        end
      end

      def run(query, *args, factory: nil, &block)
        logger.info "SQL: #{query.gsub(/\s+/, ' ')}, args: #{args.inspect}"

        results = []
        @dataset.db.fetch(query, *args) do |row|
          row = row.transform_keys(&:to_sym)
          if factory
            results << factory[row]
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
    end
  end
end
