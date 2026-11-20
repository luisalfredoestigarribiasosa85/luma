class SupplierPaymentsController < ApplicationController
  def index
    @payables = current_account.purchases
      .where(payment_method: Purchase.payment_methods[:credit])
      .includes(:supplier, :user)
      .order(created_at: :desc)
      .to_a
      .select { |purchase| purchase.balance.positive? }

    @total_owed = @payables.sum(&:balance)

    @from = parse_date(params[:from])
    @to = parse_date(params[:to])
    @from, @to = @to, @from if @from && @to && @from > @to
    @q = params[:q].presence
    @payment_method = params[:payment_method].presence_in(SupplierPayment::PAYMENT_METHODS)

    payments = current_account.supplier_payments
      .includes(purchase: %i[supplier user])
      .order(paid_on: :desc, created_at: :desc)
    payments = payments.where(paid_on: @from..@to) if @from && @to
    payments = payments.where(payment_method: @payment_method) if @payment_method
    if @q.present?
      pattern = "%#{@q.strip.downcase}%"
      payments = payments.joins(purchase: :supplier)
        .where("supplier_payments.note ILIKE ? OR suppliers.name ILIKE ? OR purchases.number ILIKE ?",
               pattern, pattern, pattern)
    end

    @payments_total = payments.sum(:amount).to_d
    @filtered_payments = payments.limit(200)
  end

  def new
    @payable = current_account.purchases.where(payment_method: Purchase.payment_methods[:credit]).find(params[:purchase_id])
    if @payable.balance <= 0
      redirect_to purchase_path(@payable), alert: "La compra ya está pagada por completo." and return
    end
    @supplier_payment = @payable.supplier_payments.build
  end

  def create
    @payable = current_account.purchases.where(payment_method: Purchase.payment_methods[:credit]).find(params[:purchase_id])
    if @payable.balance <= 0
      redirect_to purchase_path(@payable), alert: "La compra ya está pagada por completo." and return
    end
    @supplier_payment = @payable.supplier_payments.build(supplier_payment_params)
    @supplier_payment.account = current_account

    if @supplier_payment.save
      redirect_to purchase_path(@payable), notice: "Pago registrado (#{helpers.money(@supplier_payment.amount)})."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def supplier_payment_params
    params.require(:supplier_payment).permit(:payment_method, :amount, :paid_on, :note)
  end
end
