module Mentoring
  class UserRole < Drn::Framework::Entity
    primary_key :id
    reference :name, String

    alias to_s name
  end
end
