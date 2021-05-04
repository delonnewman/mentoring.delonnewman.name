module Drn
  module Mentoring
    class ProductRate < Entity
      include Recurrable
      has :id,          Integer, required: false
      has :name,        String
      has :recurring,   :boolean
      has :description, String
    end
  end
end
