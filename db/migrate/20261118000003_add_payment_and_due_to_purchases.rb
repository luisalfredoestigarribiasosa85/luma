class AddPaymentAndDueToPurchases < ActiveRecord::Migration[ 8.1 ]
  def change
    add_column :purchases, :payment_method, :integer, null: false, default: 0
    add_column :purchases, :due_date, :date
  end
end
