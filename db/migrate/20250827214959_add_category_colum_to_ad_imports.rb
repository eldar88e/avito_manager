class AddCategoryColumToAdImports < ActiveRecord::Migration[8.0]
  def change
    add_column :ad_imports, :category, :string
  end
end
