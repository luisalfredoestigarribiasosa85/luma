class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :suppliers, dependent: :destroy
  has_many :sales, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :stock_movements, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :returns, dependent: :destroy
  has_many :supplier_payments, dependent: :destroy
  has_many :cash_counts, dependent: :destroy

  MAXIMUM_SALE_NUMBER = 99_999_999

  validates :name, presence: true

  # Returns the next sequential sale number and increments the counter.
  # The counter makes numbers safe against deletions/rollbacks.
  def next_sale_number!
    with_lock do
      next_number = next_sale_number
      update!(next_sale_number: next_number + 1)
      next_number
    end
  end

  # Returns the next sequential purchase number (separate counter from sales).
  def next_purchase_number!
    with_lock do
      next_number = next_purchase_number
      update!(next_purchase_number: next_number + 1)
      next_number
    end
  end

  def can_issue_sale_number?
    next_sale_number < MAXIMUM_SALE_NUMBER
  end
end