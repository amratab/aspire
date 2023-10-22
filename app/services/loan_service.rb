class LoanService

  # when a transfer is finalized and buyer id is set,
  # player is moved to new team
  # old team's budget gets increased by player's selling price
  # new team's budget gets decreased by player's selling price
  # transfer is marked as completed and completion date is set
  def self.request(loan_params)
    # All these changes should either go together or not happen at all
    ActiveRecord::Base.transaction do
      loan = Loan.create!(loan_params)
      installment = loan.amount/loan.term
      today_date = Date.today
      loan.term.times do |n|
        loan.installments.create!(amount_due: installment, due_date: today_date+(n+1).weeks)
      end
      loan
    rescue StandardError => e
      # in case anything fails, revert all changes
      throw :abort
    end
  end
end