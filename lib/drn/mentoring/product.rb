module Drn
  module Mentoring
    class Product < Entity
      has :id,          :uuid,       required: false
      has :name,        String
      has :description, String
      has :image_path,  String
      has :amount,      Integer
      has :rate,        ProductRate, resolve_with: { Integer => :id, String => :name }
      has :meta,        Hash,        required: false, serialize: true

      def_delegator :rate, :subscription?

      def price
        amount.to_f / 100
      end

      def to_h
        if key?(:rate_id)
          super
            .merge(id: SecureRandom.uuid)
            .except(:rate)
        else
          super
            .merge(id: SecureRandom.uuid, rate_id: rate.id)
            .except(:rate)
        end
      end

      def checkout_mode
        recurring? ? 'subscription' : 'setup'
      end
    end
  end
end
