class SaleItem < ApplicationRecord
  belongs_to :sale
  belongs_to :product

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :defaults_from_product, on: :create

  def line_subtotal
    quantity.to_d * (unit_price || product&.price || 0).to_d
  end

  private

  def defaults_from_product
    return if product.nil?

    self.unit_price = product.price if unit_price.to_i.zero?
    self.unit_cost = product.cost_price if unit_cost.to_i.zero?
  end
end
