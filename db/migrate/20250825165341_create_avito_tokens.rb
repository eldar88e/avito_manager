class CreateAvitoTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :avito_tokens do |t|
      t.string :access_token, null: false
      t.integer :expires_in, null: false
      t.string :token_type, null: false
      t.references :store, null: false, foreign_key: true

      t.timestamps
    end
  end
end
