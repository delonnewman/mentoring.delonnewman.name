module Drn
  module Mentoring
    class MentoringSessionStatus < Entity
      has :id,   Integer, required: false
      has :name, String
    end
  end
end
