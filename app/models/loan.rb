class Loan < ApplicationRecord
  enum status: { pending: 0, approved: 1, paid: 2 }

  belongs_to :user
  has_many :installments, dependent: :destroy

  validates_numericality_of :amount, :greater_than => 0.0
  validates_numericality_of :term, :greater_than => 0.0
  validate :validate_status_change

  def approve!
    self.update(status: 'approved', approved_at: DateTime.now)
    self.installments.update(status: 'scheduled')
  end

  def validate_status_change
    return if status == 'pending'
    if status == 'approved' && 'paid' == status_was
        errors.add(:base, I18n.t('activerecord.errors.models.loan.not_allowed_paid_to_approved')
        )
    end
    if status == 'paid'
      if 'approved' == status_was
        errors.add(:base, I18n.t('activerecord.errors.models.loan.not_allowed_paid_with_pending_amount')
        ) if amount_due > 0
      end
      if 'pending' == status_was
        errors.add(:base, I18n.t('activerecord.errors.models.loan.not_allowed_paid_from_pending_status')
        ) if amount_due > 0
      end  
    end
  end

  def amount_due
    amount - installments.paid.pluck(:amount_paid).sum
  end
end
