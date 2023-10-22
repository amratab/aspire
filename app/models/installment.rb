class Installment < ApplicationRecord
  belongs_to :loan
  enum status: { pending: 0, scheduled: 1, paid: 2 }

  validates_presence_of :due_date
  validates_numericality_of :amount_due, :greater_than => 0.0

  def amount_to_be_paid
    amount_paid = loan.installments.paid.pluck(:amount_paid).sum
    amount_remaining = loan.amount - amount_paid
    installments_remaining = loan.installments.scheduled.count
    if installments_remaining > 1
      amount_remaining < amount_due ? amount_remaining : amount_due
    else
      amount_remaining
    end
  end
end
