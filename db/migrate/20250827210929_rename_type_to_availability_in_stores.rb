class RenameTypeToAvailabilityInStores < ActiveRecord::Migration[8.0]
  def change
    rename_column :stores, :type, :availability
  end
end
