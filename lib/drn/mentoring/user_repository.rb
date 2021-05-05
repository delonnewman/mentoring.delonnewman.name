module Drn
  module Mentoring
    class UserRepository < Repository
      def find_or_create_from_auth(auth)
        logger.info "User auth: #{auth.inspect}"
      end

      def find_user_and_authenticate(username:, password:)
        user = find_by(username: username)
        return nil unless user
        return user if user.password == password
        false
      end

      def find_user_and_authenticate!(**kwargs)
        find_user_and_authenticate(**kwargs).tap do |user|
          raise "Invalid user or password" if user.nil?
        end
      end

      ALL_QUERY = <<~SQL
          select u.*,
                 r.name as role_name
            from users u inner join user_roles r on u.role_id = r.id
      SQL

      def all(&block)
        run ALL_QUERY do |records|
          records.map do |record|
            attrs = record.reduce({}) do |h, (key, value)|
              if key.start_with?('role')
                h[:role] ||= {}
                k = key.name.sub('role_', '').to_sym
                h[:role][k] = value
              else
                h[key] = value
              end
              h
            end
            factory[attrs].tap do |entity|
              block.call(entity) if block
            end
          end
        end
      end
      alias each all
    end
  end
end
