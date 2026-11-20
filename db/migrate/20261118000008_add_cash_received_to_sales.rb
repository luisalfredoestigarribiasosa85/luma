class AddCashReceivedToSales < ActiveRecord::Migration[ 8.1 ]
  def change
    add_column :sales, :cash_received, :decimal, precision: 12, scale: 2
  end
end
