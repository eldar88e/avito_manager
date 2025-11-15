class AddExtraToAds < ActiveRecord::Migration[8.0]
  def change
    add_column :ads, :extra, :jsonb
  end
end
