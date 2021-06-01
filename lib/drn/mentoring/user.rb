module Drn
  module Mentoring
    class User < Entity
      primary_key :id

      has :displayname, String, required: false, display: { name: 'Name', order: 0 }
      has :username,    String, unique: true, display: { order: 1 }

      belongs_to :role, UserRole, display: { order: 3 }

      email display: { order: 2 }
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
