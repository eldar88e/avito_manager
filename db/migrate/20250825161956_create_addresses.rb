class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.references :store, null: false, foreign_key: true
      t.string :city, null: false
      t.string :slogan
      t.jsonb :slogan_params
      t.boolean :active, default: false, null: false
      t.string :description
      t.integer :total_games

      t.timestamps
    end
  end
end
