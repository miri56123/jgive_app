class AddIndexToPaymentIntentId < ActiveRecord::Migration[8.1]
  def change
    add_index :donations, :payment_intent_id,
              unique: true,
              where: "payment_intent_id IS NOT NULL",
              name: "index_donations_on_payment_intent_id"
  end
end
