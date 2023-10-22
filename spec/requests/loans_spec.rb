require 'rails_helper'
require 'rspec_api_documentation/dsl'

RSpec.describe Loan, type: :request do
  before(:all) do
    Loan.destroy_all
    @current_user = create(:user, password: 'abc')
    @other_user = create(:user, password: 'pqr')
    @admin_user = create(:user, password: 'admin', role: 'admin')

    @current_user_loan = create(:loan, amount: 10000, term: 2, user: @current_user)
    @current_user_loan2 = create(:loan, amount: 20000, term: 4, user: @current_user)

    @other_user_loan = create(:loan, amount: 20000, term: 5, user: @other_user)
    @other_user_loan2 = create(:loan, amount: 30000, term: 6, user: @other_user)
  end

  subject { JSON.parse(response.body) }

  resource 'Loans' do
    header 'Content-Type', 'application/json'

    get '/loans' do
      parameter :page, 'Page', required: false

      context 'when user is logged in' do
        context 'when user is admin' do
          it 'Shows users loans info', document: false do
            headers = { 'Authorization' => auth_header(@admin_user) }
            get '/loans', headers: headers
            expect(response.status).to eq(200)
            expect(subject.count).to eq(4)
            expect(subject.map{|loan| loan['id']}.sort).to eq([@current_user_loan.id, @current_user_loan2.id, @other_user_loan.id, @other_user_loan2.id].sort)
          end
        end

        context 'when user is customer' do
          it 'Shows users loans info' do
            headers = { 'Authorization' => auth_header(@current_user) }
            get '/loans', headers: headers

            expect(response.status).to eq(200)
            expect(subject.count).to eq(2)
            expect(subject.map{|loan| loan['id']}.sort).to eq([@current_user_loan.id, @current_user_loan2.id].sort)
          end
        end
      end
    end

    post '/loans' do
      parameter 'loan[amount]', 'Amount', required: true
      parameter 'loan[term]', 'Term', required: false
      context 'loan request is created' do
        let(:raw_post) do
          { loan: { amount: 50000, term: 5 } }
        end

        it 'Create a loan request' do
          headers = { 'Authorization' => auth_header(@current_user) }
          post '/loans', headers: headers, params: raw_post

          expect(response.status).to eq(201)
          expect(subject['status']).to eq('pending')
          expect(subject['amount']).to eq(50000)
          expect(subject['term']).to eq(5)
          expect(Loan.find(subject['id']).installments.count).to eq(5)
        end
      end

      context 'when an error is raised during processing' do
        let(:raw_post) do
          { loan: { amount: 50000, term: 5 } }
        end
  
        before :each do 
          allow(Loan).to receive(:create!).and_raise(StandardError, 'Some error occurred')
        end
  
        it 'should rollback all transactions', document: false do
          headers = { 'Authorization' => auth_header(@current_user) }
          post '/loans', headers: headers, params: raw_post

          expect(@current_user.loans.count).to eq(2)
        end
      end
    end

    put '/loans/:id/approve' do
      parameter :id, 'Loan Id', required: true

      context 'when user is admin user' do
        let(:id) { @current_user_loan.id }

        before :each do
          @installment1 = create(:installment, amount_due: 5000, due_date: Date.today, loan: @current_user_loan)
          @installment2 = create(:installment, amount_due: 5000, due_date: Date.today + 1.week, loan: @current_user_loan)
        end

        it 'Approve loan' do
          headers = { 'Authorization' => auth_header(@admin_user) }
          put "/loans/#{id}/approve", headers: headers

          expect(response.status).to eq(200)
          expect(subject['status']).to eq('approved')
          expect(Loan.find(subject['id']).installments.pluck(:status).uniq.first).to eq('scheduled')
        end

      end  

      context 'when user is non admin user' do
        context 'when user is loan owner' do
          let(:id) { @current_user_loan2.id }

          it 'returns error', document: false do
            headers = { 'Authorization' => auth_header(@current_user) }
            put "/loans/#{id}/approve", headers: headers
  
            expect(response.status).to eq(422)
            expect(subject['errors']).to eq(I18n.t('activerecord.errors.models.loan.only_admin_can_approve'))
          end
        end
      end
    end
  end
end