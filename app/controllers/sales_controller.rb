class SalesController < ApplicationController
  before_action :set_sale, only: %i[show cancel ticket]

  def index
    @sales = current_account.sales.order(created_at: :desc).includes(:customer, :user)
    @sales = @sales.where(status: params[:status]) if params[:status].present?
    @sales = @sales.where(payment_method: params[:payment_method]) if params[:payment_method].present?
    @sales = @sales.where(customer_id: params[:customer_id]) if params[:customer_id].present?
    @sales = @sales.where(created_at: filter_dates) if params[:from].present? && params[:to].present?
    @customers = current_account.customers.order(:name)
  end

  def show; end

  def new
    @sale = current_account.sales.build
    @products = current_account.products.active.order(:name)
    @customers = current_account.customers.order(:name)
    preselected = params[:product].present? ? @products.find_by(id: params[:product]) : nil
    @sale.items.build(product: preselected)
  end

  def create
    @sale = current_account.sales.build(sale_params)
    @sale.user = current_user

    if @sale.save
      redirect_to @sale, notice: "Venta registrada"
    else
      @products = current_account.products.active.order(:name)
      @customers = current_account.customers.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def cancel
    @sale.cancel!
    redirect_to sales_path, notice: "Venta #{@sale.number} anulada y stock restaurado"
  rescue ActiveRecord::RecordInvalid
    redirect_to @sale, alert: "No se puede anular la venta porque ya tiene pagos registrados"
  end

  def ticket
    render layout: "ticket"
  end

  private

  def set_sale
    @sale = current_account.sales.find(params[:id])
  end

  def sale_params
    params.require(:sale).permit(:customer_id, :payment_method, :discount, :note,
                                 items_attributes: [ :product_id, :quantity, :unit_price ])
  end

  def filter_dates
    from = Date.parse(params[:from]).beginning_of_day
    to = Date.parse(params[:to]).end_of_day
    from..to
  rescue ArgumentError, TypeError
    nil
  end
end