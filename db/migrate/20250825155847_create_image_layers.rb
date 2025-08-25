class CreateImageLayers < ActiveRecord::Migration[8.0]
  def change
    create_table :image_layers do |t|
      t.string :title, null: false
      t.jsonb :layer_params, default: {}
      t.integer :layer_type, default: 0, null: false
      t.references :store, null: false, foreign_key: true
      t.integer :menuindex, default: 0, null: false
      t.boolean :active, default: false, null: false

      t.timestamps
    end
  end
end
