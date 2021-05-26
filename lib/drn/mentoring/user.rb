module Drn
  module Mentoring
    class User < Entity
      reference_id

      has :displayname, String,  required: false
      has :username,    String
      has :email,       String

      belongs_to :role, UserRole, referenced_by: { Integer => :id, String => :name }

      timestamps
      encrypted_password

      def to_s
        displayname || username
      end

      def first_name
        displayname.split(/\s+/).first || username
      end
    end
  end
end
