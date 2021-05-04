Sequel.migration do
  change do
    create_table :sessions do
      String  :instant_session_id, null: false, index: true, primary_key: true
      String  :checkout_session_id, null: false
      Integer :status, null: false, index: true, default: 0
      Time    :started_at, null: false, index: true
      Time    :ended_at, index: true
    end

    create_table :products do
      String :product_id, null: false, index: true, primary_key: true
      String :price_id, null: false, index: true
      String :name, null: false, index: true
      String :description, null: false
      String :image_url, null: false
      Integer :unit_amount, null: false
      FalseClass :recurring, null: false, index: true, default: false
    end

    create_table :users do
      primary_key :id, null: false, index: true
      String  :username, null: false, index: true, unique: true
      String  :displayname
      String  :encrypted_password
      String  :email, null: false, index: true, unique: true
      Integer :role, null: false, index: true, default: 0
      Time    :created_at, index: true
      Time    :updated_at, index: true
    end
  end
end
