class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Expected cash on hand for a given date, computed from the day's sales,
  # expenses, cash purchases, supplier payments and cash refunds.
  # Used by both the caja diaria report and the arqueo (cash count).
  def expected_cash_for(date)
    day_start = date.beginning_of_day
    day_end = date.end_of_day

    sales = current_account.sales.completed.where(created_at: day_start..day_end)
    cash_income = sales.where(payment_method: Sale.payment_methods[:cash]).sum(:total).to_d
    cash_expenses = current_account.expenses.where(spent_on: date)
      .where(payment_method: Expense.payment_methods[:cash]).sum(:amount).to_d
    cash_refunds = current_account.returns.where(created_at: day_start..day_end)
      .where(refund_method: "cash").sum(:amount).to_d
    cash_purchases = current_account.purchases.where(created_at: day_start..day_end)
      .where(payment_method: Purchase.payment_methods[:cash]).sum(:total).to_d
    cash_supplier_payments = current_account.supplier_payments.where(paid_on: date)
      .where(payment_method: SupplierPayment.payment_methods[:cash]).sum(:amount).to_d

    cash_income - cash_expenses - cash_refunds - cash_purchases - cash_supplier_payments
  end

  before_action :require_login
end