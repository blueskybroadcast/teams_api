# frozen_string_literal: true

require_relative '../support/jwt_auth_implementation'

RSpec.describe TeamsApi::Auth::JwtAuthenticator do
  let(:user) { double('User') }
  let(:account) { double('Account') }
  let(:token) { "test_token_123" }
  let(:request) { double('Request', headers: {}, cookies: {}) }
  let(:controller) { double('Controller', request: request) }
  let(:authenticator) { described_class.new(controller) }

  before do
    user_class = class_double('User').as_stubbed_const
    allow(user_class).to receive(:find_by).with(id: 1).and_return(user)

    account_class = class_double('Account').as_stubbed_const
    allow(account_class).to receive(:find_by).with(id: 1).and_return(account)
  end

  describe '#authenticate' do
    context 'with valid JWT token in header' do
      before do
        allow(request).to receive(:headers).and_return({ 'Authorization' => "Bearer #{token}" })
      end

      it 'returns the current user' do
        expect(authenticator.authenticate).to eq(user)
      end

      it 'sets the current user' do
        authenticator.authenticate
        expect(authenticator.current_user).to eq(user)
      end
    end

    context 'with valid JWT token in cookie' do
      before do
        allow(request).to receive(:cookies).and_return({ 'jwt_access' => token })
      end

      it 'returns the current user' do
        expect(authenticator.authenticate).to eq(user)
      end
    end

    context 'with invalid JWT token' do
      before do
        allow(request).to receive(:headers).and_return({ 'Authorization' => "Bearer invalid_token" })
      end

      it 'returns nil' do
        expect(authenticator.authenticate).to be_nil
      end
    end

    context 'with no JWT token' do
      it 'returns nil' do
        expect(authenticator.authenticate).to be_nil
      end
    end
  end

  describe '#current_user' do
    context 'when user_id is present in payload' do
      before do
        allow(authenticator).to receive(:jwt_payload).and_return({ 'user_id' => 1 })
      end

      it 'returns the user' do
        expect(authenticator.current_user).to eq(user)
      end
    end

    context 'when user_id is not present in payload' do
      before do
        allow(authenticator).to receive(:jwt_payload).and_return({})
      end

      it 'returns nil' do
        expect(authenticator.current_user).to be_nil
      end
    end
  end

  describe '#current_account' do
    context 'when account_id is present in payload' do
      before do
        allow(authenticator).to receive(:jwt_payload).and_return({ 'account_id' => 1 })
      end

      it 'returns the account' do
        expect(authenticator.current_account).to eq(account)
      end
    end

    context 'when account_id is not present in payload' do
      before do
        allow(authenticator).to receive(:jwt_payload).and_return({})
      end

      it 'returns nil' do
        expect(authenticator.current_account).to be_nil
      end
    end
  end
end
