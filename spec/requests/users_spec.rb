# frozen_string_literal: true

require 'rails_helper'
require 'rspec_api_documentation/dsl'

RSpec.describe User, type: :request do
  before(:all) do
    @current_user = create(:user, password: 'abc')
    @other_user = create(:user, password: 'pqr')
  end

  subject { JSON.parse(response.body) }

  resource 'Users' do
    header 'Content-Type', 'application/json'

    post '/users.json' do
      parameter 'user[first_name]', 'First Name', required: true
      parameter 'user[last_name]', 'Last Name', required: false
      parameter 'user[email]', 'Email', required: true
      parameter 'user[password]', 'Password', required: true

      context 'when user is signing up' do
        let(:raw_post) do
          { user: { first_name: 'abc', last_name: 'def', email: 'abc.def@gmail.com', password: 'xyz' } }
        end

        it 'User Sign up' do
          post '/users.json', params: raw_post

          expect(response.status).to eq(201)
          user = User.find_by_email('abc.def@gmail.com')
          expect(user.first_name).to eq('abc')
          expect(user.last_name).to eq('def')
          expect(user.email).to eq('abc.def@gmail.com')
        end
      end

      context 'when user is signing up' do
        let(:raw_post) do
          { user: { first_name: 'abc', last_name: 'def', email: 'abc.def@gmail.com' } }
        end

        it 'returns error', document: false do
          post '/users.json', params: raw_post

          expect(response.status).to eq(422)
          expect(subject['errors']).to eq(['Password can\'t be blank'])
        end
      end
    end
  end
end
