class AddVideoToAdImports < ActiveRecord::Migration[8.1]
  def change
    add_column :ad_imports, :video, :string, null: true, default: nil
  end
end
