module ApiHelpers
  def json = JSON.parse(response.body)

  def csrf_token
    get '/api/v1/auth/csrf'
    json.dig('data', 'csrf_token')
  end

  def sign_in(user, password: 'TestPassword!123')
    token = csrf_token
    post '/api/v1/auth/login', params: { email: user.email, password: password },
      headers: { 'X-CSRF-Token' => token }, as: :json
    expect(response).to have_http_status(:ok)
    @token = json.dig('data', 'csrf_token')
  end

  def headers(org = @org)
    { 'X-CSRF-Token' => @token, 'X-Organization-ID' => org.id }
  end

  def create_user(label)
    User.create!(name: label, email: "#{label}@test.example", password: 'TestPassword!123')
  end

  def create_org(slug)
    organization = Organization.create!(name: slug.capitalize, slug: slug)
    { 'urgent' => [60, 240], 'high' => [240, 480], 'normal' => [480, 1440], 'low' => [1440, 4320] }.each do |priority, targets|
      organization.sla_policies.create!(priority: priority, first_response_minutes: targets[0], resolution_minutes: targets[1])
    end
    organization
  end
end
