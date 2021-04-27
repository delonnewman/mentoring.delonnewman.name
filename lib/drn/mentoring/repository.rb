module Drn
  module Mentoring
    class Repository
      include Enumerable

      def initialize(dataset, factory)
        @dataset = dataset
        @factory = factory
      end

      def logger
        App.logger
      end
  
      def each(&block)
        @dataset.each do |row|
          block.call(@factory[row])
        end
        self
      end

      def store!(record)
        @dataset.insert(record.to_h)
        self
      end

      def store_all!(records)
        @dataset.multi_insert(records.map(&:to_h))
        self
      end
  
      private

      attr_reader :dataset, :factory

      def run(query, *args, factory: nil, &block)
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
