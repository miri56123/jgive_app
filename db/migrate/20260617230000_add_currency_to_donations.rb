class AddCurrencyToDonations < ActiveRecord::Migration[8.1]
  def change
    add_column :donations, :currency, :string, default: "ILS", null: false
    add_column :donations, :exchange_rate, :decimal, precision: 10, scale: 6, default: "1.0", null: false
  end
end
