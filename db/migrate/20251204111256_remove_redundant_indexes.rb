class RemoveRedundantIndexes < ActiveRecord::Migration[8.0]
  def change
    remove_index :settings, name: :index_settings_on_user_id

    remove_index :stores, name: :index_stores_on_user_id

    remove_index :streets, name: :index_streets_on_address_id
  end
end
