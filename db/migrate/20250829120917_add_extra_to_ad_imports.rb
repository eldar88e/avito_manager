class AddExtraToAdImports < ActiveRecord::Migration[8.0]
  def change
    add_column :ad_imports, :extra, :jsonb
  end
end
