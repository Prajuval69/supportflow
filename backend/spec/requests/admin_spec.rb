require 'rails_helper'
RSpec.describe 'Administration, dashboard and notifications', type: :request do
  before do
    @org = create_org('admin')
    @other_org = create_org('foreign')
    @admin = create_user('admin')
    @agent = create_user('directoryagent')
    @customer = create_user('directorycustomer')
    @admin_member = @org.memberships.create!(user: @admin, role: 'admin')
    @agent_member = @org.memberships.create!(user: @agent, role: 'agent')
    @customer_member = @org.memberships.create!(user: @customer, role: 'customer')
    @ticket = Tickets::Create.call(organization: @org, actor: @customer, attributes: { title: 'Customer ticket', description: 'Details' })
    sign_in(@admin)
  end

  it 'adds existing and new accounts without overwriting existing credentials and audits changes' do
    new_user = create_user('existing')
    post '/api/v1/memberships', params: { membership: { email: new_user.email, password: 'OverwrittenPassword!', role: 'agent' } }, headers: headers, as: :json
    expect(response).to have_http_status(:created)
    expect(new_user.reload.authenticate('TestPassword!123')).to eq(new_user)
    post '/api/v1/memberships', params: { membership: { email: 'new@example.com', name: 'New Member', password: 'NewMemberPass!123', role: 'customer' } }, headers: headers, as: :json
    expect(response).to have_http_status(:created)
    expect(response.body).not_to include('password')
    patch "/api/v1/memberships/#{@agent_member.id}", params: { membership: { active: false } }, headers: headers, as: :json
    expect(response).to have_http_status(:ok)
    expect(@org.audit_events.count).to eq(3)
    sign_in(@agent)
    get '/api/v1/tickets', headers: headers
    expect(response).to have_http_status(:not_found)
  end

  it 'protects last admin and rejects non-admin management and cross-tenant member IDs' do
    patch "/api/v1/memberships/#{@admin_member.id}", params: { membership: { role: 'customer', active: false } }, headers: headers, as: :json
    expect(response).to have_http_status(:conflict)
    expect(@admin_member.reload).to be_active
    foreign = @other_org.memberships.create!(user: @admin, role: 'admin')
    patch "/api/v1/memberships/#{foreign.id}", params: { membership: { role: 'agent' } }, headers: headers, as: :json
    expect(response).to have_http_status(:not_found)
    sign_in(@agent)
    ['/memberships', '/categories'].each do |path|
      post "/api/v1#{path}", params: {}, headers: headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end
    patch '/api/v1/sla_policies/normal', params: { sla_policy: { resolution_minutes: 1 } }, headers: headers, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it 'manages categories and validated future-only SLA policies' do
    post '/api/v1/categories', params: { category: { name: 'Access' } }, headers: headers, as: :json
    expect(response).to have_http_status(:created)
    id = json.dig('data', 'id')
    patch "/api/v1/categories/#{id}", params: { category: { name: 'Account access', active: false } }, headers: headers, as: :json
    expect(json.dig('data', 'active')).to eq(false)
    old_deadline = @ticket.resolution_due_at
    patch '/api/v1/sla_policies/normal', params: { sla_policy: { first_response_minutes: 2, resolution_minutes: 8 } }, headers: headers, as: :json
    expect(response).to have_http_status(:ok)
    expect(@ticket.reload.resolution_due_at).to eq(old_deadline)
    patch '/api/v1/sla_policies/normal', params: { sla_policy: { resolution_minutes: -1 } }, headers: headers, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'scopes dashboard aggregates by tenant and customer ownership and accepts date filters' do
    own = Tickets::Create.call(organization: @org, actor: @admin, attributes: { title: 'Admin only', description: 'Details' })
    own.update!(resolution_due_at: 1.hour.ago)
    get '/api/v1/dashboard/summary', headers: headers
    expect(json.dig('data', 'total')).to eq(2)
    expect(json.dig('data', 'overdue')).to eq(1)
    sign_in(@customer)
    get '/api/v1/dashboard/summary', headers: headers
    expect(json.dig('data', 'total')).to eq(1)
    expect(json.dig('data', 'overdue')).to eq(0)
    expect(json.dig('data', 'recent_tickets').map { |t| t['id'] }).to eq([@ticket.id])
    get '/api/v1/dashboard/summary', params: { from: Date.tomorrow.iso8601 }, headers: headers
    expect(json.dig('data', 'total')).to eq(0)
    get '/api/v1/dashboard/summary', params: { from: 'invalid' }, headers: headers
    expect(response).to have_http_status(:bad_request)
  end

  it 'limits notifications to the recipient, tenant and currently visible ticket' do
    notification = @org.notifications.create!(user: @admin, ticket: @ticket, kind: 'assignment', message: 'Assigned', dedupe_key: 'one')
    foreign = @other_org.notifications.create!(user: @admin, kind: 'public_update', message: 'Other workspace', dedupe_key: 'two')
    get '/api/v1/notifications', headers: headers
    expect(json['data'].map { |n| n['id'] }).to eq([notification.id])
    expect(json['unread_count']).to eq(1)
    patch "/api/v1/notifications/#{notification.id}/read", headers: headers, as: :json
    expect(response).to have_http_status(:ok)
    get '/api/v1/notifications', headers: headers
    expect(json['unread_count']).to eq(0)
    patch "/api/v1/notifications/#{foreign.id}/read", headers: headers, as: :json
    expect(response).to have_http_status(:not_found)
    sign_in(@agent)
    patch "/api/v1/notifications/#{notification.id}/read", headers: headers, as: :json
    expect(response).to have_http_status(:not_found)
    sign_in(@customer)
    @org.notifications.create!(user: @customer, ticket: @ticket, kind: 'sla_breach', message: 'Private staff message', dedupe_key: 'hidden')
    get '/api/v1/notifications', headers: headers
    expect(json['data']).to eq([])
  end
end
