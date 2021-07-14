module Drn
  module Mentoring
    class UserRole < Framework::Entity
      primary_key :id
      reference :name, String

      alias to_s name
    end
  end
end
