class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.string :variable
      t.string :value
      t.string :description
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :settings, [:user_id, :variable], unique: true
  end
end
