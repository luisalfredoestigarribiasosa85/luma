class AddUnitCostToReturnItems < ActiveRecord::Migration[ 8.1 ]
  def up
    add_column :return_items, :unit_cost, :decimal, precision: 12, scale: 2, null: false, default: "0.0"

    execute <<~SQL
      UPDATE return_items
      SET unit_cost = COALESCE((
        SELECT sale_items.unit_cost
        FROM sale_items, returns
        WHERE returns.id = return_items.return_id
          AND returns.sale_id = sale_items.sale_id
          AND sale_items.product_id = return_items.product_id
        LIMIT 1
      ), 0)
    SQL
  end

  def down
    remove_column :return_items, :unit_cost
  end
end
