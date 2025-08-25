class CreateAdImports < ActiveRecord::Migration[8.0]
  def change
    create_table :ad_imports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :description
      t.bigint :price
      t.bigint :old_price
      t.string :md5_hash, null: false
      t.boolean :deleted, default: false
      t.bigint :price_updated
      t.jsonb :images, default: {}
      t.bigint :run, null: false
      t.bigint :touched_run, null: false

      t.timestamps
    end
    add_index :ad_imports, :md5_hash, unique: true
  end
end
