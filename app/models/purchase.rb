class Purchase < ApplicationRecord
  include AccountScoped

  PAYMENT_METHODS = %w[cash card transfer credit qr].freeze

  belongs_to :supplier, optional: true
  belongs_to :user, optional: true
  has_many :items, class_name: "PurchaseItem", foreign_key: :purchase_id, dependent: :destroy, inverse_of: :purchase
  has_many :supplier_payments, dependent: :restrict_with_error

  enum :payment_method, PAYMENT_METHODS.each_with_index.to_h

  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: ->(attrs) {
    attrs[ "quantity" ].blank? || attrs[ "quantity" ].to_i.zero?
  }

  validates :supplier_id, presence: true
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validates :due_date, presence: true, if: :credit?
  validate :at_least_one_item
  validate :products_belong_to_account

  before_validation :compute_totals
  before_validation :assign_user, on: :create
  before_create :assign_number
  after_create :apply_stock!

  def number
    super || ( format("%06d", id) if persisted? )
  end

  def paid_in_full?
    balance <= 0
  end

  def balance
    total.to_d - supplier_payments.sum(:amount).to_d
  end

  private

  def assign_user
    self.user ||= Current.user if Current.user
  end

  def compute_totals
    lines = items.reject(&:marked_for_destruction?)
    self.subtotal = lines.sum do |item|
      item.quantity.to_d * (item.unit_cost || 0).to_d
    end
    self.total = subtotal
  end

  def assign_number
    self.number ||= format("%06d", account.next_purchase_number!)
  end

  def at_least_one_item
    errors.add(:base, "La compra debe tener al menos un producto") if items.reject(&:marked_for_destruction?).empty?
  end

  def products_belong_to_account
    items.reject(&:marked_for_destruction?).each do |item|
      next if item.product.nil? || item.product.account_id == account_id

      errors.add(:base, "Producto inválido o no pertenece a esta cuenta")
    end
  end

  def apply_stock!
    items.each do |item|
      product = account.products.find(item.product_id)
      previous = product.stock
      new_stock = previous + item.quantity

      # Update product: add stock and refresh cost price (weighted average).
      new_cost = ((product.cost_price.to_d * previous) + (item.unit_cost.to_d * item.quantity.to_d)) / new_stock
      product.update!(stock: new_stock, cost_price: new_cost.round(2))

      StockMovement.create!(
        account: account,
        product: product,
        purchase: self,
        user: user,
        movement_type: :purchase,
        quantity: item.quantity,
        previous_quantity: previous,
        new_quantity: new_stock,
        note: "Compra #{number}"
      )
    end
  end
end
