require 'rails_helper'
RSpec.describe 'Tenant-scoped tickets', type: :request do
  before do
    @org = create_org('acme')
    @other_org = create_org('orbit')
    @customer = create_user('customer')
    @other_customer = create_user('othercustomer')
    @agent = create_user('agent')
    @other_agent = create_user('otheragent')
    @customer_member = @org.memberships.create!(user: @customer, role: 'customer')
    @org.memberships.create!(user: @other_customer, role: 'customer')
    @agent_member = @org.memberships.create!(user: @agent, role: 'agent')
    @other_org.memberships.create!(user: @other_agent, role: 'agent')
    @ticket = Tickets::Create.call(organization: @org, actor: @customer, attributes: { title: 'Account problem', description: 'Please help', priority: 'urgent' })
    @another = Tickets::Create.call(organization: @org, actor: @other_customer, attributes: { title: 'Private issue', description: 'Private' })
    sign_in(@customer)
  end

  it 'creates with inferred tenant and creator, validates fields and snapshots SLA' do
    travel_to(Time.current.change(usec: 0)) do
      post '/api/v1/tickets', params: { ticket: { title: 'New issue', description: 'Details', priority: 'high', organization_id: @other_org.id, created_by_id: @other_agent.id, assignee_id: @other_agent.id } }, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      created = @org.tickets.find(json.dig('data', 'id'))
      expect(created.created_by).to eq(@customer)
      expect(created.assignee).to be_nil
      expect(created.first_response_due_at).to eq(Time.current + 240.minutes)
      @org.sla_policies.find_by!(priority: 'high').update!(first_response_minutes: 1)
      expect(created.reload.first_response_due_at).to eq(Time.current + 240.minutes)
      expect(created.ticket_number).to eq('ACME-0003')
    end
    ['', 'x' * 201].each do |title|
      post '/api/v1/tickets', params: { ticket: { title: title, description: 'Details' } }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  it 'restricts same-tenant customer ownership on read, update, comment and events' do
    ["/tickets/#{@another.id}", "/tickets/#{@another.id}/comments", "/tickets/#{@another.id}/events"].each do |path|
      get "/api/v1#{path}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
    patch "/api/v1/tickets/#{@another.id}", params: { ticket: { status: 'resolved' } }, headers: headers, as: :json
    expect(response).to have_http_status(:not_found)
    post "/api/v1/tickets/#{@another.id}/comments", params: { comment: { body: 'Attack' } }, headers: headers, as: :json
    expect(response).to have_http_status(:not_found)
    get '/api/v1/tickets', headers: headers
    expect(json['data'].map { |t| t['id'] }).to eq([@ticket.id])
  end

  it 'denies customer mutations, internal notes and missing CSRF' do
    patch "/api/v1/tickets/#{@ticket.id}", params: { ticket: { assignee_id: @agent.id, status: 'resolved' } }, headers: headers, as: :json
    expect(response).to have_http_status(:forbidden)
    expect do
      post "/api/v1/tickets/#{@ticket.id}/comments", params: { comment: { body: 'Hidden', visibility: 'internal' } }, headers: headers, as: :json
    end.not_to change(Comment, :count)
    expect(response).to have_http_status(:forbidden)
    post '/api/v1/tickets', params: { ticket: { title: 'Issue' } }, headers: { 'X-Organization-ID' => @org.id }, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it 'hides internal content and events while setting only first public staff response' do
    sign_in(@agent)
    post "/api/v1/tickets/#{@ticket.id}/comments", params: { comment: { body: 'Sensitive note', visibility: 'internal' } }, headers: headers, as: :json
    expect(response).to have_http_status(:created)
    expect(@ticket.reload.first_response_at).to be_nil
    post "/api/v1/tickets/#{@ticket.id}/comments", params: { comment: { body: 'Public answer', visibility: 'public' } }, headers: headers, as: :json
    first = @ticket.reload.first_response_at
    expect(first).to be_present
    travel 1.hour do
      post "/api/v1/tickets/#{@ticket.id}/comments", params: { comment: { body: 'Second answer' } }, headers: headers, as: :json
      expect(@ticket.reload.first_response_at).to eq(first)
    end
    sign_in(@customer)
    get "/api/v1/tickets/#{@ticket.id}/comments", headers: headers
    expect(response.body).to include('Public answer')
    expect(response.body).not_to include('Sensitive note', 'internal')
    get "/api/v1/tickets/#{@ticket.id}/events", headers: headers
    expect(response.body).not_to include('internal_note')
    get "/api/v1/tickets/#{@ticket.id}", headers: headers
    expect(response.body).not_to include('comments_count', 'Sensitive note')
  end

  it 'assigns staff, enqueues notification, records transitions and rejects illegal ones' do
    sign_in(@agent)
    expect do
      patch "/api/v1/tickets/#{@ticket.id}", params: { ticket: { status: 'in_progress', assignee_id: @agent.id } }, headers: headers, as: :json
    end.to have_enqueued_job(TicketAssignedNotificationJob)
    expect(response).to have_http_status(:ok)
    expect(@ticket.reload.assignee).to eq(@agent)
    patch "/api/v1/tickets/#{@ticket.id}", params: { ticket: { status: 'closed' } }, headers: headers, as: :json
    expect(response).to have_http_status(:conflict)
    %w[resolved in_progress resolved closed].each do |status|
      patch "/api/v1/tickets/#{@ticket.id}", params: { ticket: { status: status } }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end
    expect(@ticket.reload.resolved_at).to be_present
    expect(@ticket.closed_at).to be_present
    post "/api/v1/tickets/#{@ticket.id}/comments", params: { comment: { body: 'Late' } }, headers: headers, as: :json
    expect(response).to have_http_status(:conflict)
  end

  it 'rejects wrong-tenant and customer assignees and categories' do
    sign_in(@agent)
    [@other_agent, @customer].each do |user|
      patch "/api/v1/tickets/#{@ticket.id}", params: { ticket: { assignee_id: user.id } }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
    category = @other_org.categories.create!(name: 'Foreign')
    post '/api/v1/tickets', params: { ticket: { title: 'Issue', description: 'Details', category_id: category.id } }, headers: headers, as: :json
    expect(response).to have_http_status(:not_found)
  end

  it 'denies other-organization access across list, search, read and all nested operations' do
    sign_in(@other_agent)
    get '/api/v1/tickets', params: { q: 'Account' }, headers: headers(@other_org)
    expect(json['data']).to eq([])
    ["/tickets/#{@ticket.id}", "/tickets/#{@ticket.id}/comments", "/tickets/#{@ticket.id}/events"].each do |path|
      get "/api/v1#{path}", headers: headers(@other_org)
      expect(response).to have_http_status(:not_found)
    end
    patch "/api/v1/tickets/#{@ticket.id}", params: { ticket: { status: 'resolved' } }, headers: headers(@other_org), as: :json
    expect(response).to have_http_status(:not_found)
    post "/api/v1/tickets/#{@ticket.id}/comments", params: { comment: { body: 'Attack' } }, headers: headers(@other_org), as: :json
    expect(response).to have_http_status(:not_found)
    get '/api/v1/tickets', headers: headers(@org)
    expect(response).to have_http_status(:not_found)
  end

  it 'paginates, filters, sorts business priority and rejects unsafe ordering' do
    sign_in(@agent)
    get '/api/v1/tickets', params: { per_page: 1000, q: 'account', priority: 'urgent', status: 'open', sort: 'priority', direction: 'desc' }, headers: headers
    expect(json.dig('meta', 'per_page')).to eq(100)
    expect(json['data'].map { |t| t['id'] }).to eq([@ticket.id])
    get '/api/v1/tickets', params: { per_page: 1, page: 2 }, headers: headers
    expect(json['data'].length).to eq(1)
    expect(json.dig('meta', 'total_pages')).to eq(2)
    get '/api/v1/tickets', params: { sort: 'title; DROP TABLE tickets' }, headers: headers
    expect(response).to have_http_status(:bad_request)
  end
end
