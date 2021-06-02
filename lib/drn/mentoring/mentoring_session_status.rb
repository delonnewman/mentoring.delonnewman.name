module Drn
  module Mentoring
    class MentoringSessionStatus < Entity
      primary_key :id
      reference :name, String

      alias to_s name
    end
  end
end
