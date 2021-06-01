module Drn
  module Mentoring
    class User < Entity
      primary_key :id

      has :displayname, String, required: false
      has :username,    String, unique: true

      belongs_to :role, UserRole

      email
      password

      timestamps

      def name
        displayname || username
      end
      alias to_s name

      def first_name
        displayname.split(/\s+/).first || username
      end
    end
  end
end
