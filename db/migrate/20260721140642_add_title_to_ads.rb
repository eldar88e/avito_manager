class AddTitleToAds < ActiveRecord::Migration[8.1]
  def change
    add_column :ads, :title, :string
  end
end
