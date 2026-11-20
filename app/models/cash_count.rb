class CashCount < ApplicationRecord
  include AccountScoped

  belongs_to :user, optional: true

  validates :counted_on, presence: true, uniqueness: { scope: :account_id }
  validates :expected, :counted, numericality: { greater_than_or_equal_to: 0 }

  before_validation :assign_user, on: :create
  before_validation :compute_difference

  private

  def assign_user
    self.user ||= Current.user if Current.user
  end

  def compute_difference
    self.difference = counted.to_d - expected.to_d
  end
end
