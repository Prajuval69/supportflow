require 'rails_helper'
RSpec.describe 'Identity and tenant context', type: :request do
  let!(:user) { create_user('identity') }
  before do
    @org = Organization.create!(name: 'Identity', slug: 'identity')
    @membership = @org.memberships.create!(user: user, role: 'admin')
  end

  it 'serves health and rejects missing sessions' do
    get '/api/v1/health'
    expect(json.dig('data', 'status')).to eq('ok')
    get '/api/v1/me'
    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects missing and invalid CSRF, including login' do
    post '/api/v1/auth/login', params: { email: user.email, password: 'TestPassword!123' }, as: :json
    expect(response).to have_http_status(:forbidden)
    post '/api/v1/auth/login', params: {}, headers: { 'X-CSRF-Token' => 'invalid' }, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it 'logs in, rotates session token and logs out with an HTTP-only cookie' do
    old_token = csrf_token
    sign_in(user)
    expect(@token).not_to eq(old_token)
    expect(response.headers['Set-Cookie'].to_s).to include('httponly')
    get '/api/v1/me'
    expect(json.dig('data', 'user', 'email')).to eq(user.email)
    expect(response.body).not_to include('password_digest')
    delete '/api/v1/auth/logout', headers: { 'X-CSRF-Token' => @token }
    expect(response).to have_http_status(:no_content)
    get '/api/v1/me'
    expect(response).to have_http_status(:unauthorized)
  end

  it 'uses a generic credential error' do
    post '/api/v1/auth/login', params: { email: user.email, password: 'incorrect' }, headers: { 'X-CSRF-Token' => csrf_token }, as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(json.dig('error', 'code')).to eq('invalid_credentials')
  end

  it 'rejects forged tenant and deactivated membership on the next request' do
    sign_in(user)
    get '/api/v1/categories', headers: headers(Organization.create!(name: 'Other', slug: 'other'))
    expect(response).to have_http_status(:not_found)
    @membership.update!(active: false)
    get '/api/v1/categories', headers: headers
    expect(response).to have_http_status(:not_found)
  end
end
