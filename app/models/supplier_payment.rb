class SupplierPayment < ApplicationRecord
  include AccountScoped

  PAYMENT_METHODS = %w[cash card transfer qr].freeze

  belongs_to :purchase
  belongs_to :user, optional: true

  enum :payment_method, PAYMENT_METHODS.each_with_index.to_h

  validates :amount, numericality: { greater_than: 0 }
  validates :paid_on, presence: true
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validate :purchase_belongs_to_account
  validate :purchase_is_credit
  validate :amount_not_exceed_balance, on: :create

  before_validation :assign_user, on: :create
  before_validation :default_paid_on

  private

  def assign_user
    self.user ||= Current.user if Current.user
  end

  def default_paid_on
    self.paid_on ||= Date.current
  end

  def purchase_belongs_to_account
    return if purchase.nil? || purchase.account_id == account_id

    errors.add(:purchase, "inválida o no pertenece a esta cuenta")
  end

  def purchase_is_credit
    return if purchase.nil? || purchase.payment_method == "credit"

    errors.add(:purchase, "no es a crédito")
  end

  def amount_not_exceed_balance
    return if purchase.nil? || amount.nil?

    if amount.to_d > purchase.balance
      errors.add(:amount, "supera el saldo pendiente de la compra (#{purchase.balance})")
    end
  end
end
