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

    def products_with_states(user:, mentors:)
      purchased = product_ids_by_customer(user)
      map do |p|
        p.merge(purchased: purchased.include?(p.id),
                disabled: p.should_disable?(user: user, mentors: mentors, products: self))
      end
    end

    SUBSCRIBERS_QUERY = <<~SQL
      select users.*,
             user_roles.id   as role[id],
             user_roles.name as role[name],
             products.id     as product_id,
        from products p
             inner join product_rates r   on r.id = p.rate_id
             inner join users_products up on ip.product_id = p.id
             inner join users u           on u.id = up.user_id
             inner join users_roles ur    on ur.id = u.role_id
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
      user_id = user.is_a?(User) ? user.id : user
      dataset.join(:users_products, product_id: Sequel[:products][:id]).where(user_id: user_id)
    end
  end
end
