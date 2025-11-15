class AddExtraSizesToAdImports < ActiveRecord::Migration[8.0]
  def change
    add_column :ad_imports, :extra_sizes, :jsonb
  end
end
