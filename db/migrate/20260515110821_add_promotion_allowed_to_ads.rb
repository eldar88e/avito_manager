class AddPromotionAllowedToAds < ActiveRecord::Migration[8.1]
  def change
    add_column :ads, :promotion_allowed, :boolean, default: true, null: false
    add_index :ads, :promotion_allowed
  end
end
