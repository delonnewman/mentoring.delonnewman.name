Sequel.migration do
  change do
    create_table? :product do
      String :product_id, null: false, index: true
      String :name, null: false, index: true
      String :description, null: false
      String :image, null: false
      Integer :price, null: false
      Integer :recurring
      Time :created_at
      Time :updated_at
      TrueClass :active, null: false, index: true, default: true

      primary_key :product_id
    end
  end
end
