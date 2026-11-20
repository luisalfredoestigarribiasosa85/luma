class ReturnItem < ApplicationRecord
  belongs_to :return, inverse_of: :items
  belongs_to :product

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }

  before_validation :defaults_from_sale, on: :create
  before_validation :compute_subtotal

  def line_subtotal
    quantity.to_d * unit_price.to_d
  end

  private

  def defaults_from_sale
    return unless sale_item = sale_item_for_product

    self.unit_price ||= sale_item.unit_price
    self.unit_cost ||= sale_item.unit_cost
    # Si la venta tuvo descuento, el reembolso respeta la proporción.
    sale = self.return&.sale
    return unless sale&.discount&.positive? && sale.subtotal.positive?

    ratio = 1 - (sale.discount.to_d / sale.subtotal.to_d)
    self.unit_price = (self.unit_price * ratio).round(2) if ratio < 1
  end

  def compute_subtotal
    self.line_subtotal = quantity.to_d * unit_price.to_d
  end

  def sale_item_for_product
    return nil unless product_id

    self.return&.sale&.items&.find_by(product_id: product_id)
  end
end
