module Drn
  module Mentoring
    class ProductRate < Entity
      primary_key :id
      reference :name, String

      has :description,  String,   required: false
      has :subscription, :boolean, default: false

      alias to_s name
    end
  end
end
