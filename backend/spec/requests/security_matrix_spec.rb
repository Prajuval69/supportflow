require 'rails_helper'
RSpec.describe 'Security regression matrix', type: :request do
  before do
    @org = create_org('matrix')
    @user = create_user('matrixadmin')
    @membership = @org.memberships.create!(user: @user, role: 'admin')
    @ticket = Tickets::Create.call(organization: @org, actor: @user, attributes: { title: 'Matrix ticket', description: 'Scoped content' })
    @category = @org.categories.create!(name: 'Matrix')
    @notification = @org.notifications.create!(user: @user, ticket: @ticket, kind: 'public_update', message: 'Update', dedupe_key: 'matrix')
    sign_in(@user)
  end

  it 'rejects missing CSRF on every mutation route, without database writes' do
    endpoints = [
      [:post, '/tickets', { ticket: { title: 'Attempt', description: 'Attempt' } }],
      [:patch, "/tickets/#{@ticket.id}", { ticket: { status: 'resolved' } }],
      [:post, "/tickets/#{@ticket.id}/comments", { comment: { body: 'Attempt' } }],
      [:patch, "/notifications/#{@notification.id}/read", {}],
      [:post, '/memberships', { membership: { email: 'attack@example.com' } }],
      [:patch, "/memberships/#{@membership.id}", { membership: { active: false } }],
      [:post, '/categories', { category: { name: 'Attempt' } }],
      [:patch, "/categories/#{@category.id}", { category: { name: 'Attempt' } }],
      [:patch, '/sla_policies/normal', { sla_policy: { first_response_minutes: 1 } }],
      [:delete, '/auth/logout', {}]
    ]
    baseline = [Ticket.count, Comment.count, Membership.count, Category.count]
    endpoints.each do |method, path, body|
      public_send(method, "/api/v1#{path}", params: body, headers: { 'X-Organization-ID' => @org.id }, as: :json)
      expect(response).to have_http_status(:forbidden), "CSRF accepted for #{method} #{path}"
    end
    expect([Ticket.count, Comment.count, Membership.count, Category.count]).to eq(baseline)
    expect(@notification.reload.read_at).to be_nil
  end

  it 'rejects a valid token sent from an untrusted Origin' do
    post '/api/v1/tickets', params: { ticket: { title: 'Attempt', description: 'Attempt' } },
      headers: headers.merge('Origin' => 'https://attacker.example'), as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it 'switches a dual member between different roles without widening customer scope' do
    other = create_org('dual')
    other.memberships.create!(user: @user, role: 'customer')
    other_admin = create_user('dualadmin')
    other.memberships.create!(user: other_admin, role: 'admin')
    hidden = Tickets::Create.call(organization: other, actor: other_admin, attributes: { title: 'Private other ticket', description: 'Private' })
    get '/api/v1/me'
    expect(json.dig('data', 'memberships').map { |m| m['role'] }).to contain_exactly('admin', 'customer')
    get '/api/v1/tickets', headers: headers(other)
    expect(json['data']).to eq([])
    get "/api/v1/tickets/#{hidden.id}", headers: headers(other)
    expect(response).to have_http_status(:not_found)
    get '/api/v1/memberships', headers: headers(other)
    expect(response).to have_http_status(:forbidden)
  end

  it 'keeps historical tickets workable after their creator is deactivated' do
    @membership.update!(active: false)
    other_admin = create_user('replacement')
    member = @org.memberships.create!(user: other_admin, role: 'admin')
    expect { Tickets::Update.call(ticket: @ticket, membership: member, attributes: { status: 'in_progress' }) }.to change { @ticket.reload.status }.to('in_progress')
  end

  it 'preloads ticket references with a bounded number of SQL reads' do
    10.times { |i| Tickets::Create.call(organization: @org, actor: @user, attributes: { title: "Query #{i}", description: 'Details', category_id: @category.id }) }
    queries = []
    subscriber = lambda do |_name, _start, _finish, _id, payload|
      queries << payload[:sql] if payload[:sql].start_with?('SELECT') && !payload[:cached] && payload[:name] != 'SCHEMA'
    end
    ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') do
      TicketList.call(@org.tickets, {}).limit(20).map { |ticket| TicketSerializer.call(ticket) }
    end
    expect(queries.length).to be <= 4
  end
end
