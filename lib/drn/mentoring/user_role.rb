module Drn
  module Mentoring
    class UserRole < Entity
      reference_id
      has :name, String

      alias to_s name
    end
  end
end
