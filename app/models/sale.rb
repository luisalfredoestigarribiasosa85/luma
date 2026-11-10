class Sale < ApplicationRecord
  include AccountScoped

  STATUSES = %w[completed cancelled].freeze
  PAYMENT_METHODS = %w[cash card transfer credit qr].freeze

  belongs_to :customer, optional: true
  belongs_to :user, optional: true
  has_many :items, class_name: "SaleItem", foreign_key: :sale_id, dependent: :destroy, inverse_of: :sale
  has_many :payments, dependent: :restrict_with_error
  has_many :stock_movements, dependent: :nullify

  enum :status, STATUSES.each_with_index.to_h
  enum :payment_method, PAYMENT_METHODS.each_with_index.to_h

  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: ->(attrs) {
    attrs[ "quantity" ].blank? || attrs[ "quantity" ].to_i.zero?
  }

  scope :credit, -> { where(payment_method: payment_methods[ :credit ]) }

  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validates :discount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :at_least_one_item
  validate :sufficient_stock, on: :create
  validate :products_belong_to_account
  validate :customer_belongs_to_account
  validate :customer_required_for_credit

  before_validation :compute_totals
  before_validation :assign_user, on: :create
  before_create :assign_number
  after_create :apply_stock!

  def number
    super || ( format("%06d", id) if persisted? )
  end

  def cancel!
    return if cancelled?

    if payments.any?
      raise ActiveRecord::RecordInvalid, self
    end

    transaction do
      restore_stock!
      update_column(:status, self.class.statuses[ :cancelled ])
    end
  end

  # The amount still owed by the customer for this sale.
  def balance
    total.to_d - payments.sum(:amount).to_d
  end

  def paid_in_full?
    balance <= 0
  end

  private

  def assign_user
    self.user ||= Current.user if Current.user
  end

  def compute_totals
    lines = items.reject(&:marked_for_destruction?)
    self.subtotal = lines.sum(&:line_subtotal)
    self.discount = 0 if discount.to_f.negative?
    self.total = (subtotal - discount.to_d).clamp(0, subtotal)
  end

  def assign_number
    self.number ||= format("%06d", account.next_sale_number!)
  end

  def at_least_one_item
    errors.add(:base, "La venta debe tener al menos un producto") if items.reject(&:marked_for_destruction?).empty?
  end

  def sufficient_stock
    return if status != "completed"

    items.reject(&:marked_for_destruction?).each do |item|
      product = item.product
      next unless product

      if product.stock < item.quantity
        errors.add(:base, "#{product.name}: stock insuficiente (#{product.stock} disponibles)")
      end
    end
  end

  def products_belong_to_account
    items.reject(&:marked_for_destruction?).each do |item|
      next if item.product.nil? || item.product.account_id == account_id

      errors.add(:base, "Producto inválido o no pertenece a esta cuenta")
    end
  end

  def customer_belongs_to_account
    return if customer.nil? || customer.account_id == account_id

    errors.add(:base, "Cliente inválido o no pertenece a esta cuenta")
  end

  def customer_required_for_credit
    return unless payment_method == "credit"

    errors.add(:customer, "es obligatorio en ventas a crédito") if customer.blank?
  end

  def restore_stock!
    items.each do |item|
      product = account.products.find(item.product_id)
      previous = product.stock
      new_stock = previous + item.quantity
      product.update!(stock: new_stock)

      StockMovement.create!(
        account: account,
        product: product,
        sale: self,
        user: Current.user,
        movement_type: :return,
        quantity: item.quantity,
        previous_quantity: previous,
        new_quantity: new_stock,
        note: "Anulación de venta #{number}"
      )
    end
  end

  def apply_stock!
    items.each do |item|
      product = account.products.find(item.product_id)
      previous = product.stock
      new_stock = previous - item.quantity
      product.update!(stock: new_stock)

      StockMovement.create!(
        account: account,
        product: product,
        sale: self,
        user: user,
        movement_type: :sale,
        quantity: -item.quantity,
        previous_quantity: previous,
        new_quantity: new_stock,
        note: "Venta #{number}"
      )
    end
  end
end