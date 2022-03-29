module El
  class Entity
    module Types
      def timestamp(name)
        has name, :time, edit: false, default: -> { Time.now }
      end

      def timestamps
        timestamp :created_at
        timestamp :updated_at
      end

      El::Types.define_alias(:password, ->(v) { v.is_a?(String) && v.length > 10 || v.is_a?(BCrypt::Password) })

      def password
        has :encrypted_password,
            :string,
            required: false,
            display: false,
            edit: false,
            default: -> { BCrypt::Password.create(password) }

        has :password,
            :password,
            required: false,
            display: false,
            default: -> { BCrypt::Password.new(encrypted_password) }

        exclude_for_storage << :password

        :password
      end

      EMAIL_REGEXP = %r{\A[a-zA-Z0-9!#$%&'*+/=?\^_`{|}~\-]+(?:\.[a-zA-Z0-9!#$%&'*+/=?\^_`{|}~\-]+)*@(?:[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?$\z}
      El::Types.define_alias :email, El::Types::RegExpType[EMAIL_REGEXP]

      def email(name = :email, **options)
        has name, :email, **options
      end
    end
  end
end
