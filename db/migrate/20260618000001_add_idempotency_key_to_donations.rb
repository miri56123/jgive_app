class AddIdempotencyKeyToDonations < ActiveRecord::Migration[8.1]
  def change
    add_column :donations, :idempotency_key, :string
    add_index :donations, :idempotency_key, unique: true,
              where: "idempotency_key IS NOT NULL"
  end
end
