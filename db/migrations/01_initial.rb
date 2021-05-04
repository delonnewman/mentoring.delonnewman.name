Sequel.migration do
  change do
    create_table :mentoring_sessions do
      uuid    :mentoring_session_id, null: false, index: true, primary_key: true
      String  :checkout_session_id,  null: false
      Integer :status_id,            null: false, index: true
      Time    :started_at,           null: false, index: true
      Time    :ended_at,                          index: true
    end

    create_table :mentoring_session_statuses do
      primary_key :id
      String      :name, null: false, index: true, unique: true
    end

    create_table :products do
      uuid    :product_id,  null: false, index: true, primary_key: true
      String  :name,        null: false, index: true
      String  :description, null: false
      Integer :amount,      null: false
      Integer :rate_id,     null: false
      String  :meta
    end

    # (e.g. per month, per minute, per hour)
    create_table :rates do
      primary_key :id
      String      :name,        null: false, index: true, unique: true
      FalseClass  :recurring,   null: false, index: true, default: false
      String      :description, null: false
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
    end

    create_table :roles do
      primary_key :id
      String      :name, null: false, index: true, unique: true
    end
  end
end
