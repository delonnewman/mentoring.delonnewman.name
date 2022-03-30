module El
  class Entity
    module Types
      def timestamp(name)
        define_attribute(name, :time, default: -> { Time.now })
      end

      def timestamps
        timestamp :created_at
        timestamp :updated_at
      end

      El::Types.define_alias(:password, ->(v) { v.is_a?(String) && v.length > 10 || v.is_a?(BCrypt::Password) })

      def password
        meta = { required: false, default: -> { BCrypt::Password.create(password) } }
        define_attribute(:encrypted_password, :string, **meta)

        meta.merge!(exclude_for_storage: true, default: -> { BCrypt::Password.new(encrypted_password) })
        define_attribute(:password, :password, **meta)

        :password
      end

      EMAIL_REGEXP = %r{\A[a-zA-Z0-9!#$%&'*+/=?\^_`{|}~\-]+(?:\.[a-zA-Z0-9!#$%&'*+/=?\^_`{|}~\-]+)*@(?:[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?$\z}
      El::Types.define_alias :email, El::Types::RegExpType[EMAIL_REGEXP]

      def email(name = :email, **options)
        define_attribute(name, :email, **options)
      end
    end
  end
end
