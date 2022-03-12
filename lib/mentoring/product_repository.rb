# frozen_string_literal: true

module Mentoring
  # A Collection of Product objects and methods on that collection
  class ProductRepository < El::Repository
    order_by :sort_order

    def subscribe(product, user)
      product = find!(product)
      user = app.users.find!(user)
      db[:users_products].insert(product_id: product.id, user_id: user.id, created_at: Time.now)
    end

    def products_by_customer(user)
      customer_products(user).map(&method(:entity))
    end

    def product_ids_by_customer(user)
      customer_products(user).select_map(Sequel[:products][:id])
    end

    WITH_STATES_QUERY = <<~SQL.squish
          select *,
          (select p.id
             from products p
                  inner join users_products up on up.product_id = p.id
            where up.user_id in (?)) as subscribed,
          (select u.id
            from users u
                 inner join sessions s on s.mentor_id = u.id
           where s.ended_at is not null
           group by u.id) as mentors_available
      from products
    SQL

    # TODO: replace this with the query above.  We just need to be able
    # to determine mentor availability.  We could do this by:
    #  1) making user meta data a JSON column, or
    #  2) by making a meta data EAV table.
    def products_with_states(user:, mentors:)
      purchased = product_ids_by_customer(user)
      map do |p|
        p.merge(purchased: purchased.include?(p.id),
                disabled: should_disable?(p, user: user, mentors: mentors))
      end
    end

    def subscribed?(product, user:)
      return false unless product.subscription? || user.nil?

      product_ids_by_customer(user).include?(product.id)
    end

    def should_disable?(product, user:, mentors:)
      return unless product.instant? || product.ongoing?
      return mentors.none?(&:available?) if product.instant?

      subscribed?(product, user: user)
    end

    SUBSCRIBERS_QUERY = <<~SQL.squish
      select u.*,
             ur.id   as "role[id]",
             ur.name as "role[name]",
             p.id    as product_id
        from products p
             inner join product_rates r   on r.id = p.rate_id
             inner join users_products up on up.product_id = p.id
             inner join users u           on u.id = up.user_id
             inner join user_roles ur     on ur.id = u.role_id
       where r.subscription
    SQL

    def subscribers
      records = []
      db.fetch(SUBSCRIBERS_QUERY) do |row|
        records << El::SqlUtils.build_entity(User, row)
      end
      records
    end

    private

    def customer_products(user)
      user_id = user.respond_to?(:id) ? user.id : user
      dataset.join(:users_products, product_id: Sequel[:products][:id]).where(user_id: user_id)
    end
  end
end
