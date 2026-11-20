class Return < ApplicationRecord
  include AccountScoped

  REFUND_METHODS = %i[cash card transfer credit_note].freeze
  # cash | card | transfer → sale moneys a devolver por caja (o se transfieren de vuelta)
  # credit_note → no sale plata: descuenta lo que el cliente debía en ventas a crédito

  belongs_to :sale
  belongs_to :user, optional: true
  has_many :items, class_name: "ReturnItem", foreign_key: :return_id, dependent: :destroy, inverse_of: :return

  enum :refund_method, REFUND_METHODS.each_with_index.to_h

  before_validation :assign_user, on: :create
  before_validation :compute_total
  before_validation :assign_defaults, on: :create
  after_create :apply!

  validates :amount, numericality: { greater_than: 0 }
  validates :refund_method, inclusion: { in: REFUND_METHODS.map(&:to_s) }
  validate :items_present
  validate :items_returnable

  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: ->(attrs) {
    attrs[ "quantity" ].blank? || attrs[ "quantity" ].to_i.zero?
  }

  def credit_note?
    refund_method == "credit_note"
  end

  def refund_method_label
    {
      "cash" => "Reembolso en efectivo",
      "card" => "Reembolso (tarjeta)",
      "transfer" => "Reembolso (transferencia)",
      "credit_note" => "A cuenta del cliente (crédito)"
    }.fetch(refund_method, refund_method)
  end

  private

  def assign_user
    self.user ||= Current.user if Current.user
  end

  def assign_defaults
    self.refund_method ||= "cash"
  end

  def compute_total
    self.amount = items.reject(&:marked_for_destruction?).sum(&:line_subtotal)
  end

  def items_present
    errors.add(:base, "La devolución debe incluir al menos un producto") if items.reject(&:marked_for_destruction?).empty?
  end

  def items_returnable
    items.reject(&:marked_for_destruction?).each do |item|
      sold = sale.items.where(product_id: item.product_id).sum(:quantity)
      returned = ReturnItem.joins(:return)
        .where("returns.sale_id = ?", sale_id)
        .where("returns.id != ?", id || 0)
        .where(product_id: item.product_id)
        .sum(:quantity)
      remaining = sold - returned
      if item.quantity > remaining
        errors.add(:base, "#{item.product.variant_label}: solo quedan #{remaining} unidades por devolver")
      end
    end
  end

  def apply!
    items.each do |item|
      product = account.products.find(item.product_id)
      previous = product.stock
      new_stock = previous + item.quantity
      product.update!(stock: new_stock)

      StockMovement.create!(
        account: account,
        product: product,
        sale: sale,
        user: user,
        movement_type: :return,
        quantity: item.quantity,
        previous_quantity: previous,
        new_quantity: new_stock,
        note: "Devolución de venta ##{sale.number}"
      )
    end
  end
end
