class Expense < ApplicationRecord
  include AccountScoped

  CATEGORIES = %w[restocking wages rent utilities freight maintenance marketing taxes other].freeze
  CATEGORY_LABELS = {
    "restocking" => "Reposición de mercadería",
    "wages" => "Sueldos y cargas",
    "rent" => "Alquiler",
    "utilities" => "Servicios",
    "freight" => "Fletes y transporte",
    "maintenance" => "Mantenimiento",
    "marketing" => "Marketing",
    "taxes" => "Impuestos",
    "other" => "Otros"
  }.freeze
  PAYMENT_METHODS = %w[cash card transfer credit qr].freeze

  belongs_to :user, optional: true

  enum :category, CATEGORIES.each_with_index.to_h
  enum :payment_method, PAYMENT_METHODS.each_with_index.to_h

  validates :description, :spent_on, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :category, inclusion: { in: CATEGORIES }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }

  before_validation :default_spent_on
  before_validation :assign_user, on: :create

  def category_label
    CATEGORY_LABELS[ category ] || category
  end

  def self.category_options
    CATEGORIES.map { |key| [ CATEGORY_LABELS[ key ], key ] }
  end

  private

  def default_spent_on
    self.spent_on ||= Date.current
  end

  def assign_user
    self.user ||= Current.user if Current.user
  end
end
