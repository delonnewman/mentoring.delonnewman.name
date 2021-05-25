module Drn
  module Mentoring
    class UserRole < Entity
      has :id,   Integer, required: false
      has :name, String

      alias to_s name
    end
  end
end
