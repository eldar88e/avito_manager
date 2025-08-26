class RenameRunColumnsInAdImports < ActiveRecord::Migration[8.0]
  def change
    rename_column :ad_imports, :run, :run_id
    rename_column :ad_imports, :touched_run, :touched_run_id
  end
end
