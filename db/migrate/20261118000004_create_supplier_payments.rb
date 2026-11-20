class CreateSupplierPayments < ActiveRecord::Migration[ 8.1 ]
  def change
    create_table :supplier_payments do |t|
      t.references :account, null: false, foreign_key: true
      t.references :purchase, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :payment_method, null: false, default: 0
      t.decimal :amount, precision: 12, scale: 2, null: false, default: "0.0"
      t.date :paid_on, null: false
      t.text :note

      t.timestamps
    end

    add_index :supplier_payments, %i[ account_id paid_on ]
  end
end
