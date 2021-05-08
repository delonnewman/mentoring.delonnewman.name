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
            factory[nest_role(record)].tap do |entity|
              block.call(entity) if block
            end
          end
        end
      end
      alias each all

      ONE_QUERY = <<~SQL
        select u.*,
               r.name as role_name
          from users u inner join user_roles r on u.role_id = r.id /* where */ limit 1
      SQL

      ATTRIBUTE_MAP = Hash.new { |_, key| key }
      ATTRIBUTE_MAP[:id] = :'u.id'

      def find_by(predicates)
        preds       = predicates.transform_keys(&ATTRIBUTE_MAP)
        pp preds
        qstr, binds = sql_where(preds)
        query       = ONE_QUERY.sub('/* where */', qstr)
        records     = run(query, *binds)
        return nil if records.empty?
        factory[nest_role(records.first)]
      end

      private

      def nest_role(record)
        record.reduce({}) do |h, (key, value)|
          if key.start_with?('role')
            h[:role] ||= {}
            k = key.name.sub('role_', '').to_sym
            h[:role][k] = value
          else
            h[key] = value
          end
          h
        end
      end

      def sql_where(predicates)
        preds = predicates.map do |(key, value)|
          kstr = Symbol ? key.name : key.to_s

          k = 
            if not kstr.include?('.')
              Sequel.identifier(kstr)
            else
              kstr.split('.').reduce do |a, b|
                if a.respond_to?(:qualify)
                  a.qualify(b)
                else
                  Sequel.qualify(a, b)
                end
              end
            end

          "#{db.literal(k)} = ?"
        end

        ["where #{preds.join(' and ')}", predicates.values]
      end
    end
  end
end
