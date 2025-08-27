class CreateAds < ActiveRecord::Migration[8.0]
  def change
    create_table :ads do |t|
      t.references :store, null: false, foreign_key: true
      t.references :address, null: false, foreign_key: true
      t.string :file_id
      t.references :adable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true
      t.boolean :deleted, default: false, null: false
      t.boolean :banned, default: false, null: false
      t.datetime :banned_until
      t.bigint :avito_id
      t.string :full_address

      t.timestamps
    end
  end
end
