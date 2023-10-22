# frozen_string_literal: true

##
# Process all status updates after payment
#
class PaymentService
  attr_reader :loan, :installment, :amount

  def initialize(loan: , installment: , amount: )
    @loan = loan
    @installment = installment
    @amount = amount
  end

  # when payment is done against an installment
  def process!
    # All these changes should either go together or not happen at all
    raise I18n.t('activerecord.errors.models.installment.payment_not_allowed_for_unapproved') if @loan.pending?
    validate_amount_paid
    ActiveRecord::Base.transaction do
      mark_eligible_installments_as_paid
      mark_loan_as_paid
      @installment
    rescue StandardError => e
      # in case anything fails, revert all changes
      throw :abort
    end
  end

  def validate_amount_paid
    if @amount > loan_amount_due
      raise I18n.t('activerecord.errors.models.installment.amount_greater_than_loan_due', loan_amount_due: loan_amount_due)
    end
    if @amount < @installment.amount_due && loan_amount_due >= @installment.amount_due
      raise I18n.t('activerecord.errors.models.installment.amount_less_than_installment', amount_due: @installment.amount_due)
    end
    true
  end

  def mark_eligible_installments_as_paid
    @installment.update(status: 'paid', paid_at: DateTime.now, amount_paid: @amount)
    return if loan_amount_due > 0
    @loan.installments.scheduled.update(status: 'paid')
  end

  def loan_amount_due
    @loan.amount - @loan.installments.paid.pluck(:amount_paid).sum
  end

  def mark_loan_as_paid
    @loan.update(status: 'paid') if loan_amount_due <= 0
  end
end
