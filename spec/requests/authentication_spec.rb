# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authentications', type: :request do
  before(:all) do
    @current_user = create(:user, password: 'abc')
  end

  subject { JSON.parse(response.body) }

  resource 'Authentications' do
    header 'Content-Type', 'application/json'

    post '/auth/login' do
      parameter :email, 'Email', required: true
      parameter :password, 'Password', required: true

      context 'when user is logging in with correct password' do
        let(:raw_post) { { email: @current_user.email, password: 'abc' } }

        it 'Returns authentication token' do
          post '/auth/login', params: raw_post
          expect(response.status).to eq(200)
          expect(subject['token']).to eq(auth_header(@current_user).split(' ').last)
        end
      end

      context 'when password is wrong' do
        let(:raw_post) { { email: @current_user.email, password: 'kbc' } }

        it 'returns error', document: false do
          post '/auth/login', params: raw_post

          expect(response.status).to eq(401)
          expect(subject['error']).to eq(I18n.t('errors.unauthorized'))
        end
      end
    end
  end
end
