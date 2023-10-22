require 'rails_helper'
require 'rspec_api_documentation/dsl'

RSpec.describe Installment, type: :request do
  before(:all) do
    Loan.destroy_all
    @current_user = create(:user, password: 'abc')
    @other_user = create(:user, password: 'pqr')
    @admin_user = create(:user, password: 'admin', role: 'admin')

    @current_user_loan = create(:loan, amount: 10000, term: 2, user: @current_user)
    @installment1 = create(:installment, amount_due: 5000, due_date: Date.today, loan: @current_user_loan)
    @installment2 = create(:installment, amount_due: 5000, due_date: Date.today + 1.week, loan: @current_user_loan)
  end

  subject { JSON.parse(response.body) }

  resource 'Installments' do
    header 'Content-Type', 'application/json'

    get '/loans/:loan_id/installments' do
      parameter :page, 'Page', required: false

      context 'when user is loan owner' do
        let(:loan_id) { @current_user_loan.id }

        it 'Display all installments for loan' do
          headers = { 'Authorization' => auth_header(@current_user) }
          get "/loans/#{loan_id}/installments", headers: headers

          expect(response.status).to eq(200)
          expect(subject.count).to eq(2)
          expect(subject.map{|ins| ins['id']}.sort).to eq([@installment1.id, @installment2.id].sort)
        end
      end

      context 'when user is not loan owner but a customer' do
        let(:loan_id) { @current_user_loan.id }

        it 'Returns error message', document: false do
          headers = { 'Authorization' => auth_header(@other_user) }
          get "/loans/#{loan_id}/installments", headers: headers

          expect(response.status).to eq(404)
          expect(subject['errors']).to eq(I18n.t('activerecord.errors.models.loan.not_found'))
        end
      end

      context 'when user is not loan owner but admin' do
        let(:loan_id) { @current_user_loan.id }

        it 'Shows users loans installments info', document: false do
          headers = { 'Authorization' => auth_header(@admin_user) }
          get "/loans/#{loan_id}/installments", headers: headers

          expect(response.status).to eq(200)
          expect(subject.count).to eq(2)
          expect(subject.map{|ins| ins['id']}.sort).to eq([@installment1.id, @installment2.id].sort)
        end
      end
    end

    put '/loans/:loans_id/installments/:id/pay' do
      parameter 'payment[amount]', 'Amount', required: true

      context 'user is loan owner or admin' do
        before :each do
          @other_user_loan = create(:loan, amount: 20000, term: 5, user: @other_user)
          @other_installment1 = create(:installment, amount_due: 4000, due_date: Date.today + 1.week, loan: @other_user_loan)
          @other_installment2 = create(:installment, amount_due: 4000, due_date: Date.today + 2.weeks, loan: @other_user_loan)
          @other_installment3 = create(:installment, amount_due: 4000, due_date: Date.today + 3.weeks, loan: @other_user_loan)
          @other_installment4 = create(:installment, amount_due: 4000, due_date: Date.today + 4.weeks, loan: @other_user_loan)
          @other_installment5 = create(:installment, amount_due: 4000, due_date: Date.today + 5.weeks, loan: @other_user_loan)
        end

        context 'when no scheduled installment is present' do
          let(:loan_id) { @other_user_loan.id }
          let(:id) { @other_installment1.id }
          let(:raw_post) do
            { payment: { amount: 25000 } }
          end
  
          it 'Returns error message', document: false do
            headers = { 'Authorization' => auth_header(@other_user) }
            put "/loans/#{loan_id}/installments/#{id}/pay", headers: headers, params: raw_post
  
            expect(response.status).to eq(404)
            expect(subject['errors']).to eq(I18n.t('activerecord.errors.models.installment.scheduled_installment_not_found', id: id))
          end
        end

        context 'when payment amount is more than loan due amount' do
          before :each do
            @other_user_loan.approve!
          end

          let(:loan_id) { @other_user_loan.id }
          let(:id) { @other_installment1.id }

          let(:raw_post) do
            { payment: { amount: 25000 } }
          end
  
          it 'Returns error message', document: false do
            headers = { 'Authorization' => auth_header(@other_user) }
            put "/loans/#{loan_id}/installments/#{id}/pay", headers: headers, params: raw_post
  
            expect(response.status).to eq(422)
            expect(subject['errors']).to eq(I18n.t('activerecord.errors.models.installment.amount_greater_than_loan_due', loan_amount_due: 20000.0))
          end
        end

        context 'when loan due amount is more than installment amount and paid amount is less than installment amount' do
          before :each do
            @other_user_loan.approve!
          end

          let(:loan_id) { @other_user_loan.id }
          let(:id) { @other_installment1.id }

          let(:raw_post) do
            { payment: { amount: 3000 } }
          end
  
          it 'Returns error message', document: false do
            headers = { 'Authorization' => auth_header(@other_user) }
            put "/loans/#{loan_id}/installments/#{id}/pay", headers: headers, params: raw_post
  
            expect(response.status).to eq(422)
            expect(subject['errors']).to eq(I18n.t('activerecord.errors.models.installment.amount_less_than_installment', amount_due: @other_installment1.amount_due))
          end
        end

        context 'when paid amount is more than installment amount' do

          context 'when loan amount is paid off after this payment' do
            before :each do
              @other_user_loan.approve!
              @other_installment1.update(status: 'paid', amount_paid: 10000)
            end

            let(:loan_id) { @other_user_loan.id }
            let(:id) { @other_installment2.id }

            let(:raw_post) do
              { payment: { amount: 10000 } }
            end
    
            it 'Pay installment' do
              headers = { 'Authorization' => auth_header(@other_user) }
              put "/loans/#{loan_id}/installments/#{id}/pay", headers: headers, params: raw_post
    
              expect(response.status).to eq(200)
              expect(Loan.find(subject['id']).installments.pluck(:status).uniq.first).to eq('paid')
              expect(Installment.find(id).amount_paid).to eq(10000)
              expect(Installment.where(id: [@other_installment3.id, @other_installment4.id, @other_installment5.id]).pluck(:amount_paid)).to eq([0,0,0])
            end
          end

          context 'when loan amount is still pending after this payment' do
            before :each do
              @other_user_loan.approve!
              @other_installment1.update(status: 'paid', amount_paid: 10000)
            end

            let(:loan_id) { @other_user_loan.id }
            let(:id) { @other_installment2.id }

            let(:raw_post) do
              { payment: { amount: 8000 } }
            end
    
            it 'Updates loan status and all installments status', document: false do
              headers = { 'Authorization' => auth_header(@other_user) }
              put "/loans/#{loan_id}/installments/#{id}/pay", headers: headers, params: raw_post
    
              expect(response.status).to eq(200)
              expect(subject['status']).to eq('approved')
              expect(Installment.find(id).status).to eq('paid')
              expect(Installment.find(id).amount_paid).to eq(8000)
              expect(Installment.where(id: [@other_installment3.id, @other_installment4.id, @other_installment5.id]).pluck(:status)).to eq(['scheduled','scheduled','scheduled'])
            end
          end

          context 'when loan amount pending is less than installment amount' do
            before :each do
              @other_user_loan.approve!
              @other_installment1.update(status: 'paid', amount_paid: 10000)
              @other_installment2.update(status: 'paid', amount_paid: 8000)
            end

            let(:loan_id) { @other_user_loan.id }
            let(:id) { @other_installment3.id }

            let(:raw_post) do
              { payment: { amount: 2000 } }
            end
    
            it 'Updates loan status and all installments status', document: false do
              headers = { 'Authorization' => auth_header(@other_user) }
              put "/loans/#{loan_id}/installments/#{id}/pay", headers: headers, params: raw_post
    
              expect(response.status).to eq(200)
              expect(subject['status']).to eq('paid')
              expect(Installment.find(id).status).to eq('paid')
              expect(Installment.find(id).amount_paid).to eq(2000)
              expect(Installment.where(id: [@other_installment4.id, @other_installment5.id]).pluck(:status)).to eq(['paid','paid'])
            end
          end

          context 'when an error is raised during processing' do
            before :each do
              @other_user_loan.approve!
              @other_installment1.update(status: 'paid', amount_paid: 10000)
              @other_installment2.update(status: 'paid', amount_paid: 8000)
              allow_any_instance_of(PaymentService).to receive(:validate_amount_paid).and_raise(StandardError, 'Some error occurred')
            end

            let(:loan_id) { @other_user_loan.id }
            let(:id) { @other_installment3.id }

            let(:raw_post) do
              { payment: { amount: 2000 } }
            end

            it 'should rollback all transactions', document: false do
              headers = { 'Authorization' => auth_header(@other_user) }
              put "/loans/#{loan_id}/installments/#{id}/pay", headers: headers, params: raw_post
    
              expect(response.status).to eq(422)
              expect(subject['errors']).to eq(I18n.t('errors.generic'))
            end
          end
        end
        
      end

      context 'user is not loan owner' do
        let(:loan_id) { @current_user_loan.id }
        let(:id) { @installment1.id }
        let(:raw_post) do
          { payment: { amount: 5000 } }
        end

        it 'Returns error message', document: false do
          headers = { 'Authorization' => auth_header(@other_user) }
          put "/loans/#{loan_id}/installments/#{id}/pay", headers: headers, params: raw_post

          expect(response.status).to eq(404)
          expect(subject['errors']).to eq(I18n.t('activerecord.errors.models.loan.not_found'))
        end
      end
    end
  end
end