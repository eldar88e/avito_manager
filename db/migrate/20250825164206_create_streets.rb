class CreateStreets < ActiveRecord::Migration[8.0]
  def change
    create_table :streets do |t|
      t.string :title, null: false
      t.references :address, null: false, foreign_key: true

      t.timestamps
    end

    add_index :streets, [:address_id, :title], unique: true
  end
end
