class AddVariantFieldsToProducts < ActiveRecord::Migration[ 8.1 ]
  def change
    add_column :products, :size,  :string
    add_column :products, :color, :string
    add_index :products, %i[ account_id size ]
  end
end
