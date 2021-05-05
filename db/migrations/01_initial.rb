Sequel.migration do
  change do
    create_table :mentoring_session_statuses do
      primary_key :id
      String      :name, null: false, index: true, unique: true
    end

    create_table :mentoring_sessions do
      uuid    :id,                   null: false, index: true, primary_key: true
      String  :checkout_session_id,  null: false
      Integer :status_id,            null: false, index: true
      Time    :started_at,           null: false, index: true
      Time    :ended_at,                          index: true

      foreign_key [:status_id], :mentoring_session_statuses
    end

    # (e.g. per month, per minute, per hour)
    create_table :product_rates do
      primary_key :id
      String      :name,         null: false, index: true, unique: true
      FalseClass  :subscription, null: false, index: true, default: false
      String      :description,  null: false
    end

    create_table :products do
      uuid    :id,          null: false, index: true, primary_key: true
      String  :name,        null: false, index: true
      String  :description, null: false
      String  :image_path,  null: false
      Integer :amount,      null: false
      Integer :rate_id,     null: false
      String  :meta

      foreign_key [:rate_id], :product_rates
    end

    create_table :user_roles do
      primary_key :id
      String      :name, null: false, index: true, unique: true
    end

    create_table :users do
      primary_key :id,                 null: false, index: true
      String      :username,           null: false, index: true, unique: true
      String      :displayname
      String      :encrypted_password
      String      :email,              null: false, index: true, unique: true
      Integer     :role_id,            null: false, index: true
      Time        :created_at,                      index: true
      Time        :updated_at,                      index: true

      foreign_key [:role_id], :user_roles
    end
  end
end
