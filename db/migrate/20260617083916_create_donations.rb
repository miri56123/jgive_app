class CreateDonations < ActiveRecord::Migration[8.1]
  def change
    create_table :donations do |t|
      t.references :campaign, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.integer :frequency, null: false, default: 0
      t.integer :display_preference, null: false, default: 0
      t.string :donor_name
      t.text :dedication_message
      t.integer :status, null: false, default: 0
      t.string :payment_intent_id

      t.timestamps
    end

    add_index :donations, [ :campaign_id, :status ]
  end
end
