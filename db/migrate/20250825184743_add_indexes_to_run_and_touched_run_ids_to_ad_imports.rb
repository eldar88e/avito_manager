class AddIndexesToRunAndTouchedRunIdsToAdImports < ActiveRecord::Migration[8.0]
  def change
    add_index :ad_imports, :run_id
    add_index :ad_imports, :touched_run_id
  end
end
