module Drn
  module Mentoring
    class UserRole < Entity
      has :id,   Integer, required: false
      has :name, String
    end
  end
end
