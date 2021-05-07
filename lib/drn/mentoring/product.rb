module Drn
  module Mentoring
    class Product < Entity
      has :id,          :uuid,      default: ->{ SecureRandom.uuid }
      has :name,        String
      has :description, String
      has :image_path,  String
      has :amount,      Integer
      has :rate,        ProductRate, resolve_with: { Integer => :id, String => :name }
      has :meta,        Hash,        required: false, serialize: true
      has :sort_order,  Integer

      def_delegator :rate, :subscription?

      def price
        amount.to_f / 100
      end

      def to_h
        h = super.except(:rate)
        if !key?(:rate_id)
          h.merge!(rate_id: rate.id)
        else
          h
        end
      end

      def checkout_mode
        recurring? ? 'subscription' : 'setup'
      end
    end
  end
end
