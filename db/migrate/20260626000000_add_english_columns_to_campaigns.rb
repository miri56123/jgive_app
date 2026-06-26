class AddEnglishColumnsToCampaigns < ActiveRecord::Migration[8.1]
  def change
    add_column :campaigns, :title_en, :string
    add_column :campaigns, :subtitle_en, :string
    add_column :campaigns, :organization_name_en, :string
    add_column :campaigns, :description_en, :text
  end
end
