class CreateExpenses < ActiveRecord::Migration[ 8.1 ]
  def change
    create_table :expenses do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :category, null: false, default: 0
      t.integer :payment_method, null: false, default: 0
      t.string :description, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false, default: "0.0"
      t.date :spent_on, null: false
      t.text :note

      t.timestamps
    end

    add_index :expenses, %i[ account_id spent_on ]
  end
end
