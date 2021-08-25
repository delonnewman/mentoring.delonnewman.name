module Drn
  module Mentoring
    class ProductRate < Framework::Entity
      primary_key :id
      reference :name, String

      has :unit, String
      has :description, String, required: false
      has :subscription, :boolean, default: false

      alias to_s name
    end
  end
end
