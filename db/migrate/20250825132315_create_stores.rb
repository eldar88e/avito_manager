class CreateStores < ActiveRecord::Migration[8.0]
  def change
    create_table :stores do |t|
      t.references :user, null: false, foreign_key: true
      t.string "var", null: false
      t.string "ad_status"
      t.string "category", null: false
      t.string "goods_type", null: false
      t.string "ad_type", null: false
      t.text "description", null: false
      t.string "condition", null: false
      t.string "allow_email", null: false
      t.string "manager_name", null: false
      t.string "contact_phone", null: false
      t.integer "menuindex", default: 0
      t.jsonb :img_params
      t.boolean "active", default: false, null: false
      t.string :contact_method
      t.text :desc_game
      t.text :desc_product
      t.string :type
      t.string :client_id
      t.string :client_secret
      t.integer :percent, default: 0, null: false

      t.timestamps
    end

    add_index :stores, :contact_phone, unique: true
    add_index :stores, [:user_id, :var], unique: true
  end
end
