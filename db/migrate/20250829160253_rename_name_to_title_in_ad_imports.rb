class RenameNameToTitleInAdImports < ActiveRecord::Migration[8.0]
  def change
    rename_column :ad_imports, :name, :title
  end
end
