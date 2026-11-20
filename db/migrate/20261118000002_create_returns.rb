class CreateReturns < ActiveRecord::Migration[ 8.1 ]
  def change
    create_table :returns do |t|
      t.references :account, null: false, foreign_key: true
      t.references :sale, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :refund_method, null: false, default: 0
      t.decimal :amount, precision: 12, scale: 2, null: false, default: "0.0"
      t.text :note

      t.timestamps
    end

    create_table :return_items do |t|
      t.references :return, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 12, scale: 2, null: false, default: "0.0"
      t.decimal :line_subtotal, precision: 12, scale: 2, null: false, default: "0.0"

      t.timestamps
    end

    add_index :returns, %i[ account_id created_at ]
  end
end
