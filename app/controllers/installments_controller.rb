class InstallmentsController < ApplicationController
  before_action :set_loan
  before_action :set_installment, only: [:pay]
  before_action :set_amount, only: [:pay]
  
  def index
    @installments = @loan.installments.paginate(page: params[:page], per_page: 10)
    render json: @installments, status: :ok
  end

  def pay
    @payment = PaymentService.new(loan: @loan, installment: @installment, amount: @amount).process!
    render json: @loan ,
           status: :ok
    rescue => e
      render json: { errors: e.message || I18n.t('errors.generic') },
           status: :unprocessable_entity
  end

  private
  def set_loan
    @loan = @current_user.admin? ? Loan.find(params[:loan_id]) : @current_user.loans.find(params[:loan_id])
  rescue ActiveRecord::RecordNotFound
    respond_with_not_found(I18n.t('activerecord.errors.models.loan.not_found'))
  end

  def set_installment
    @installment = @loan.installments.scheduled.find(params[:installment_id])
  rescue ActiveRecord::RecordNotFound
    respond_with_not_found(I18n.t('activerecord.errors.models.installment.scheduled_installment_not_found', id: params[:installment_id]))
  end

  def set_amount
    @amount = payment_params[:amount].is_a?(String) ? payment_params[:amount].to_f : payment_params[:amount]
  end

  def payment_params
    params.require(:payment).permit(:amount)
  end
end
