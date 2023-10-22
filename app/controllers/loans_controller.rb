class LoansController < ApplicationController
    before_action :set_loan, only: [:approve]
    
    def index
      if @current_user.admin?
        @loans = Loan.all
      else
        @loans = @current_user.loans
      end
      @loans = @loans.includes(:user).order(:created_at).paginate(page: params[:page], per_page: 10)
      render json: @loans.to_json(:include => [:user]), status: :ok
    end

    def approve
      if @current_user.admin?
        @loan.approve!
        render json: @loan, status: :ok
      else
        render json: { errors: I18n.t('activerecord.errors.models.loan.only_admin_can_approve') },
               status: :unprocessable_entity
      end
    end

    def create
      @loan = LoanService.request(loan_params.merge(user: @current_user))
      render json: @loan, status: :created
      rescue => e
        render json: { errors: e.message },
               status: :unprocessable_entity
    end

    private
    def set_loan
      @loan = Loan.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      respond_with_not_found(I18n.t('activerecord.errors.models.loan.not_found'))
    end

    def loan_params
      params.require(:loan).permit(:amount, :term)
    end
end
