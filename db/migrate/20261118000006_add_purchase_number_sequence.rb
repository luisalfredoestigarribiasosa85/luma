class AddPurchaseNumberSequence < ActiveRecord::Migration[ 8.1 ]
  def up
    add_column :accounts, :next_purchase_number, :integer, null: false, default: 1

    execute <<~SQL
      UPDATE accounts
      SET next_purchase_number = COALESCE((
        SELECT MAX(NULLIF(number, '')::integer) + 1
        FROM purchases
        WHERE purchases.account_id = accounts.id
      ), 1)
    SQL
  end

  def down
    remove_column :accounts, :next_purchase_number
  end
end
