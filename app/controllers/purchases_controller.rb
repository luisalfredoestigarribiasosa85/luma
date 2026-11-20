class PurchasesController < ApplicationController
  before_action :set_purchase, only: %i[show]
  before_action :set_products_and_suppliers, only: %i[new create]

  def index
    @purchases = current_account.purchases.order(created_at: :desc).includes(:supplier, :user)
    @purchases = @purchases.where(supplier_id: params[:supplier_id]) if params[:supplier_id].present?
    @purchases = @purchases.where(created_at: filter_dates) if params[:from].present? && params[:to].present?
    @suppliers = current_account.suppliers.order(:name)
  end

  def show; end

  def new
    @purchase = current_account.purchases.build
    @purchase.items.build
  end

  def create
    @purchase = current_account.purchases.build(purchase_params)
    @purchase.user = current_user

    if @purchase.save
      redirect_to @purchase, notice: "Compra registrada y stock actualizado"
    else
      set_products_and_suppliers
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_purchase
    @purchase = current_account.purchases.find(params[:id])
  end

  def set_products_and_suppliers
    @products = current_account.products.order(:name)
    @suppliers = current_account.suppliers.order(:name)
  end

  def purchase_params
    params.require(:purchase).permit(:supplier_id, :note, :payment_method, :due_date,
                                     items_attributes: [ :product_id, :quantity, :unit_cost ])
  end

  def filter_dates
    from = Date.parse(params[:from]).beginning_of_day
    to = Date.parse(params[:to]).end_of_day
    from..to
  rescue ArgumentError, TypeError
    nil
  end
end
