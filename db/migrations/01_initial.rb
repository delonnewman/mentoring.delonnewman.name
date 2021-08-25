Sequel.migration do
  change do
    # (e.g. per month, per minute, per hour)
    create_table :product_rates do
      primary_key :id
      String :name, null: false, index: true, unique: true
      FalseClass :subscription, null: false, index: true, default: false
      String :description, null: false
    end

    create_table :products do
      uuid :id, null: false, index: true, primary_key: true
      String :name, null: false, index: true
      String :description, null: false
      String :image_path, null: false
      Integer :amount, null: false
      Integer :rate_id, null: false
      Integer :sort_order, null: false, default: 0
      String :meta

      foreign_key [:rate_id], :product_rates
    end

    create_table :user_roles do
      primary_key :id
      String :name, null: false, index: true, unique: true
    end

    create_table :users do
      primary_key :id, null: false, index: true
      String :username, null: false, index: true, unique: true
      String :displayname
      String :encrypted_password
      String :email, null: false, index: true
      Integer :role_id, null: false, index: true
      Time :created_at, index: true
      Time :updated_at, index: true
      FalseClass :mentor, index: true, default: false
      String :meta

      foreign_key [:role_id], :user_roles
    end

    create_table :users_products do
      uuid :product_id, null: false, index: true
      Integer :user_id, null: false, index: true
      Time :created_at, index: true

      foreign_key [:product_id], :products
      foreign_key [:user_id], :users
    end

    create_table :mentoring_sessions do
      uuid :id, null: false, index: true, primary_key: true
      String :checkout_session_id
      Time :started_at, null: false, index: true
      Time :ended_at, index: true
      Integer :mentor_id, null: false, index: true
      Integer :customer_id, null: false, index: true
      bigint :zoom_meeting_id, null: false, index: true
      uuid :product_id, null: false, index: true

      foreign_key [:mentor_id], :users
      foreign_key [:customer_id], :users
      foreign_key [:product_id], :products
    end

    create_table :user_registrations do
      uuid :id, null: false, index: true, primary_key: true
      String :username, null: false, index: true
      String :email, null: false, index: true
      String :activation_key, null: false

      Time :expires_at, index: true
      Time :created_at, index: true
      Time :updated_at, index: true
    end
  end
end
