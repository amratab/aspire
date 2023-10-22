require 'rails_helper'

RSpec.describe Loan, type: :model do
  it { should validate_numericality_of(:amount) }
  it { should validate_numericality_of(:term) }
  it { should belong_to(:user) }

  describe 'amount_due' do
    context 'when amount due is called' do
      let(:user) { create(:user, password: 'xyz') }
      let(:loan) { create(:loan, user: user, amount: 30000, term: 3) }
      let(:installment1) { create(:installment, amount_due: 10000, due_date: Date.today + 1.week, amount_paid: 10000, loan: loan, status: 'paid') }
      let(:installment2) { create(:installment, amount_due: 10000, due_date: Date.today + 2.weeks, amount_paid: 10000, loan: loan, status: 'paid') }
      let(:installment3) { create(:installment, amount_due: 10000, due_date: Date.today + 3.weeks, amount_paid: 0, loan: loan) }

      before :each do
        allow(loan).to receive_message_chain('installments.paid').and_return([installment1, installment2])
      end

      it 'returns unpaid amount for the loan' do
        expect(loan.amount_due).to eq(10000)
      end
    end
  end

  describe 'validate_status_change' do
    context 'when status is pending' do
      let(:user) { create(:user, password: 'xyz') }
      let(:loan) { create(:loan, user: user) }
      
      it 'should add no errors' do
        loan.update(status: 'pending')
        expect(loan.errors.count).to eq(0)
      end
    end

    context 'when status is not pending' do
      context 'when status is paid' do
        
      end

      context 'when status is approved' do
        context 'when status was paid' do
          let(:user) { create(:user, password: 'xyz') }
          let(:loan) { create(:loan, user: user) }
          
          before :each do
            allow(loan).to receive(:status_was).and_return('paid')
          end

          it 'should not allow save' do
            loan.update(status: 'approved')
            expect(loan.errors.count).to eq(1)
            expect(loan.errors[:base]).to eq([I18n.t('activerecord.errors.models.loan.not_allowed_paid_to_approved')])
          end
        end

        context 'when status was not paid' do
          context 'when status was approved' do
            context 'when loan is still unpaid' do
              let(:user) { create(:user, password: 'xyz') }
              let(:loan) { create(:loan, user: user, status: 'approved') }
    
                before :each do 
                  allow(loan).to receive(:amount_due).and_return(100)
                end
                
                it 'should not allow save' do
                  loan.update(status: 'paid')
                  expect(loan.errors.count).to eq(1)
                  expect(loan.errors[:base]).to eq([I18n.t('activerecord.errors.models.loan.not_allowed_paid_with_pending_amount')])
                end
              end
    
              context 'when loan is paid' do
                let(:user) { create(:user, password: 'xyz') }
                let(:loan) { create(:loan, user: user, status: 'approved') }
      
                before :each do 
                  allow(loan).to receive(:amount_due).and_return(0)
                end
                
                it 'should not allow save' do
                  loan.update(status: 'paid')
                  expect(loan.errors.count).to eq(0)
                end
              end
              
            end
          end

          context 'when status was pending' do
            let(:user) { create(:user, password: 'xyz') }
            let(:loan) { create(:loan, user: user) }
  
            it 'should not allow save' do
              loan.update(status: 'paid')
              expect(loan.errors.count).to eq(1)
              expect(loan.errors[:base]).to eq([I18n.t('activerecord.errors.models.loan.not_allowed_paid_from_pending_status')])
            end
          end
          
      end

    end
  end
end
