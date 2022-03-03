module Mentoring
  class UserRole < El::Entity
    primary_key :id
    reference :name, String

    alias to_s name
  end
end
