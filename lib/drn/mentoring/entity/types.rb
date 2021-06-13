module Drn
  module Mentoring
    class Entity
      module Types
        CLASSICAL_TYPE = ->(klass) { ->(v) { v.is_a?(klass) } }
        DEFAULT_TYPE   = CLASSICAL_TYPE[Object]
        REGEXP_TYPE    = ->(regex) { ->(v) { v.is_a?(String) && !!(regex =~ v) } }
        UUID_REGEXP    = /\A[0-9A-Fa-f]{8,8}\-[0-9A-Fa-f]{4,4}\-[0-9A-Fa-f]{4,4}\-[0-9A-Fa-f]{4,4}\-[0-9A-Fa-f]{12,12}\z/.freeze
        EMAIL_REGEXP   = /\A[a-zA-Z0-9!#\$%&'*+\/=?\^_`{|}~\-]+(?:\.[a-zA-Z0-9!#\$%&'\*+\/=?\^_`{|}~\-]+)*@(?:[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?$\z/.freeze
  
        SPECIAL_TYPES = {
          boolean: ->(v) { v.is_a?(FalseClass) || v.is_a?(TrueClass) },
          string:  CLASSICAL_TYPE[String],
          any:     CLASSICAL_TYPE[BasicObject],
          uuid:    REGEXP_TYPE[UUID_REGEXP],
          email:   REGEXP_TYPE[EMAIL_REGEXP],
          # TODO: add more checks here
          password: ->(v) { v.is_a?(String) && v.length > 10 || v.is_a?(BCrypt::Password) }
        }

        def timestamp(name)
          has name, Time, edit: false, default: ->{ Time.now }
        end

        def timestamps
          timestamp :created_at
          timestamp :updated_at
        end

        def password
          has :encrypted_password, String,
              required: false,
              display:  false,
              edit:     false,
              default:  ->{ BCrypt::Password.create(password) }

          has :password, :password,
              required: false,
              display:  false,
              default:  ->{ BCrypt::Password.new(encrypted_password) }

          exclude_for_storage << :password

          :password
        end

        def email(name = :email, **options)
          has name, :email, **options
        end
      end
    end
  end
end
