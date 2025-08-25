class RenameDescGameToDescAdImportInStores < ActiveRecord::Migration[8.0]
  def change
    rename_column :stores, :desc_game, :desc_ad_import
  end
end
