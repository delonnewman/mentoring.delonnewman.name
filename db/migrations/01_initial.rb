Sequel.migration do
  change do
    create_table? :product do
      primary_key :product_id
      String :name, null: false, index: true
      String :image, null: false
      Integer :price, null: false
      Integer :recurring
    end
  end
end
