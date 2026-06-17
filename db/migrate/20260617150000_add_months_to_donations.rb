class AddMonthsToDonations < ActiveRecord::Migration[8.1]
  def change
    add_column :donations, :months, :integer
  end
end
