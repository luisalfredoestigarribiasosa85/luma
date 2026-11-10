class Payment < ApplicationRecord
  include AccountScoped

  PAYMENT_METHODS = %w[cash card transfer qr].freeze

  belongs_to :customer
  belongs_to :sale
  belongs_to :user, optional: true

  enum :payment_method, PAYMENT_METHODS

  validates :amount, numericality: { greater_than: 0 }
  validate :customer_belongs_to_account
  validate :sale_belongs_to_account
  validate :sale_is_credit
  validate :sale_is_completed
  validate :amount_not_exceed_balance, on: :create

  before_validation :assign_user, on: :create

  private

  def assign_user
    self.user ||= Current.user if Current.user
  end

  def customer_belongs_to_account
    return if customer.nil? || customer.account_id == account_id

    errors.add(:customer, "inválido o no pertenece a esta cuenta")
  end

  def sale_belongs_to_account
    return if sale.nil? || sale.account_id == account_id

    errors.add(:sale, "inválida o no pertenece a esta cuenta")
  end

  def sale_is_credit
    return if sale.nil? || sale.payment_method == "credit"

    errors.add(:sale, "no es una venta a crédito")
  end

  def sale_is_completed
    return if sale.nil? || sale.completed?

    errors.add(:sale, "no está completada (no se puede cobrar una venta anulada)")
  end

  def amount_not_exceed_balance
    return if sale.nil? || amount.nil?

    if amount.to_d > sale.balance
      errors.add(:amount, "supera el saldo pendiente de la venta (#{sale.balance} Gs.)")
    end
  end
end