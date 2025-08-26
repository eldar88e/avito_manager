class AddExternalIdToAdImports < ActiveRecord::Migration[8.0]
  def change
    add_column :ad_imports, :external_id, :string
  end
end
