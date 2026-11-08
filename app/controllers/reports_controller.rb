class ReportsController < ApplicationController
  def daily_cash
    @date = (Date.parse(params[:date]) rescue Date.current)
    @date = Date.current if @date > Date.current

    day_start = @date.beginning_of_day
    day_end = @date.end_of_day
    @sales = current_account.sales.completed.where(created_at: day_start..day_end)

    @total = @sales.sum(:total)

    @by_payment = {}
    Sale.payment_methods.each_key do |method|
      @by_payment[method] = @sales.where(payment_method: method).sum(:total)
    end

    @discount_total = @sales.sum(:discount).to_d
    @sale_count = @sales.count
    @customer_count = @sales.where.not(customer_id: nil).distinct.count(:customer_id)

    @day_expenses = current_account.expenses.where(spent_on: @date).includes(:user).order(created_at: :desc)
    @cash_expenses = @day_expenses.where(payment_method: Expense.payment_methods[:cash]).sum(:amount).to_d
    @cash_income = @by_payment["cash"].to_d
    @cash_expected = @cash_income - @cash_expenses
  end

  def profit
    range = report_range
    @from = range.begin.to_date
    @to = range.end.to_date

    completed = current_account.sales.completed.where(created_at: range)
    @sale_count = completed.count
    @revenue = completed.sum(:total).to_d
    @cogs = completed.joins(:items).sum("sale_items.quantity * sale_items.unit_cost").to_d
    @gross = @revenue - @cogs
    @gross_margin = @revenue.positive? ? (@gross / @revenue * 100) : 0

    @expenses = current_account.expenses.where(spent_on: @from..@to)
    @expenses_total = @expenses.sum(:amount).to_d
    @expenses_by_category = @expenses.group(:category).sum(:amount)
                                     .map { |key, amount| [ Expense::CATEGORIES[key.to_i] || key, amount ] }
                                     .sort_by { |_, amount| -amount }

    @purchases_total = current_account.purchases.where(created_at: range).sum(:total).to_d

    @net = @gross - @expenses_total
    @net_margin = @revenue.positive? ? (@net / @revenue * 100) : 0
  end

  def sales_report
    range = report_range
    completed = current_account.sales.completed.where(created_at: range)

    @from = range.begin
    @to = range.end

    @sale_count = completed.count
    @total = completed.sum(:total)
    @discount_total = completed.sum(:discount).to_d
    @unit_count = completed.joins(:items).sum("sale_items.quantity")

    @profit = current_account.sales
      .joins(:items)
      .where(status: Sale.statuses[ :completed ], created_at: range)
      .sum("sale_items.quantity * (sale_items.unit_price - sale_items.unit_cost)")
      .to_d
    @margin = @total.positive? ? (@profit / @total.to_d * 100) : 0.0

    @daily_totals = completed.group("created_at::date").sum(:total).sort_by(&:first)

    @top_products = current_account.sales
      .joins(items: :product)
      .where(status: Sale.statuses[:completed], created_at: range)
      .group("products.id", "products.name")
      .select("products.name", "SUM(sale_items.quantity) AS total_quantity",
              "SUM(sale_items.quantity * sale_items.unit_price) AS total_amount",
              "SUM(sale_items.quantity * (sale_items.unit_price - sale_items.unit_cost)) AS total_profit")
      .order("total_profit DESC")
      .limit(10)

    @by_category = current_account.sales
      .joins(items: { product: :category })
      .where(status: Sale.statuses[:completed], created_at: range)
      .group("categories.name")
      .select("categories.name", "SUM(sale_items.quantity) AS total_quantity",
              "SUM(sale_items.quantity * sale_items.unit_price) AS total_amount",
              "SUM(sale_items.quantity * (sale_items.unit_price - sale_items.unit_cost)) AS total_profit")
      .order("total_profit DESC")

    @by_seller = completed.joins(:user).group("users.name").sum(:total).sort_by { |_, v| -v }

    respond_to do |format|
      format.html
      format.csv { send_data sales_csv(range), filename: csv_filename, type: "text/csv" }
    end
  end

  private

  def report_range
    from = parse_date(params[:from]) || Date.current.at_beginning_of_month
    to = parse_date(params[:to]) || Date.current
    from, to = to, from if from > to
    from.beginning_of_day..to.end_of_day
  end

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def sales_csv(range)
    rows = [ [ "N°", "Fecha", "Cliente", "Producto", "Cantidad", "Precio unitario", "Subtotal" ] ]

    current_account.sales.completed
      .where(created_at: range)
      .includes(:customer, items: :product)
      .find_each do |sale|
        sale.items.each do |item|
          rows << [
            sale.number,
            I18n.l(sale.created_at, format: :long),
            sale.customer&.name || "Consumidor final",
            item.product.name,
            item.quantity,
            item.unit_price.to_f,
            item.line_subtotal.to_f
          ]
        end
      end

    CSV.generate(col_sep: ";") { |csv| rows.each { |row| csv << row } }
  end

  def csv_filename
    "ventas_#{@from.strftime("%Y%m%d")}_#{@to.strftime("%Y%m%d")}.csv"
  end
end
