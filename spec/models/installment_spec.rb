require 'rails_helper'

RSpec.describe Installment, type: :model do
  it { should validate_numericality_of(:amount_due) }
  it { should validate_presence_of(:due_date) }
  it { should belong_to(:loan) }

  describe 'amount_to_be_paid' do
    context 'when loan amount remaining is less than installment amount' do
      let(:user) { create(:user, password: 'xyz') }
      let(:loan) { create(:loan, user: user, amount: 30000, term: 3) }
      let(:installment1) { create(:installment, amount_due: 10000, due_date: Date.today + 1.week, amount_paid: 10000, loan: loan, status: 'paid') }
      let(:installment2) { create(:installment, amount_due: 10000, due_date: Date.today + 2.weeks, amount_paid: 15000, loan: loan, status: 'paid') }
      let(:installment3) { create(:installment, amount_due: 10000, due_date: Date.today + 3.weeks, amount_paid: 0, loan: loan) }

      before :each do
        allow(loan).to receive_message_chain('installments.paid').and_return([installment1, installment2])
        allow(loan).to receive_message_chain('installments.scheduled.count').and_return(1)
      end

      it 'returns unpaid amount for the loan' do
        expect(installment3.amount_to_be_paid).to eq(5000)
      end
    end

    context 'when loan amount remaining is more than installment amount' do
      let(:user) { create(:user, password: 'xyz') }
      let(:loan) { create(:loan, user: user, amount: 30000, term: 3) }
      let(:installment1) { create(:installment, amount_due: 10000, due_date: Date.today + 1.week, amount_paid: 15000, loan: loan, status: 'paid') }
      let(:installment2) { create(:installment, amount_due: 10000, due_date: Date.today + 2.weeks, loan: loan) }
      let(:installment3) { create(:installment, amount_due: 10000, due_date: Date.today + 3.weeks, loan: loan) }

      before :each do
        allow(loan).to receive_message_chain('installments.paid').and_return([installment1])
        allow(loan).to receive_message_chain('installments.scheduled.count').and_return(2)
      end

      it 'returns unpaid amount for the loan' do
        expect(installment2.amount_to_be_paid).to eq(10000.0)
      end
    end
  end
end
