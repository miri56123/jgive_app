class CreateCampaigns < ActiveRecord::Migration[8.1]
  def change
    create_table :campaigns do |t|
      t.string :title, null: false
      t.string :subtitle
      t.text :description
      t.string :organization_name
      t.string :cover_image_url
      t.decimal :goal_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :bonus_goal_amount, precision: 12, scale: 2
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
