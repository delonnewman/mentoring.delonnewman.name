Sequel.migration do
  change do
    create_table :sessions do
      String  :instant_session_id, null: false, index: true
      String  :checkout_session_id, null: false
      Integer :status, null: false, index: true, default: 0
      Time    :started_at, null: false, index: true
      Time    :ended_at, index: true

      primary_key :instant_session_id
    end
  end
end
