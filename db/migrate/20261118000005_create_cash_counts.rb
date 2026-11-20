class CreateCashCounts < ActiveRecord::Migration[ 8.1 ]
  def change
    create_table :cash_counts do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.date :counted_on, null: false
      t.decimal :expected, precision: 12, scale: 2, null: false, default: "0.0"
      t.decimal :counted,  precision: 12, scale: 2, null: false, default: "0.0"
      t.decimal :difference, precision: 12, scale: 2, null: false, default: "0.0"
      t.text :note

      t.timestamps
    end

    add_index :cash_counts, %i[ account_id counted_on ], unique: true
  end
end
