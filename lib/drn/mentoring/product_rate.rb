module Drn
  module Mentoring
    class ProductRate < Entity
      has :id,           Integer, required: false
      has :name,         String
      has :description,  String
      has :subscription, :boolean, default: false
    end
  end
end
