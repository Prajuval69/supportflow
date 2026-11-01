abort 'Demo seeds must never run in production' if Rails.env.production?
password = ENV.fetch('DEMO_PASSWORD') { Rails.env.development? ? 'DemoPass!12345' : abort('Set DEMO_PASSWORD for test seeds') }
ApplicationRecord.transaction do
  organizations = {}
  { 'acme' => ['Acme Support', 18, 2, 3], 'orbit' => ['Orbit Labs', 7, 1, 2] }.each do |prefix, (name, count, agent_count, customer_count)|
    org = Organization.find_or_create_by!(slug: "#{prefix}-demo") { |o| o.name = name }
    organizations[prefix] = org
    SlaPolicy::DEFAULTS.each do |priority, (first, resolution)|
      org.sla_policies.find_or_create_by!(priority: priority) { |p| p.first_response_minutes = first; p.resolution_minutes = resolution }
    end
    categories = %w[Account Billing Technical].map { |category| org.categories.find_or_create_by!(name: category) }
    accounts = [['admin', 'admin']] + (1..agent_count).map { |i| ["agent#{i}", 'agent'] } + (1..customer_count).map { |i| ["customer#{i}", 'customer'] }
    accounts.each do |label, role|
      user = User.find_or_create_by!(email: "#{label}@#{prefix}.example") { |u| u.name = "#{prefix.capitalize} #{label.capitalize}"; u.password = password }
      org.memberships.find_or_create_by!(user: user) { |m| m.role = role }
    end
    customers = org.memberships.where(role: 'customer').includes(:user).order(:created_at).map(&:user)
    agents = org.memberships.active.staff.includes(:user).order(:created_at).map(&:user)
    subjects = ['Cannot access my account', 'Invoice needs a correction', 'Export is taking too long', 'Update account email', 'Payment status is pending', 'Team invitation not received', 'Report shows missing entries', 'Need help with permissions', 'Dashboard not refreshing']
    count.times do |i|
      next if org.tickets.exists?(ticket_number: "#{prefix.upcase}-#{(i + 1).to_s.rjust(4, '0')}")
      ticket = Tickets::Create.call(organization: org, actor: customers[i % customers.length], attributes: {
        title: "#{subjects[i % subjects.length]}#{i >= subjects.length ? ' (follow-up)' : ''}",
        description: 'Our team needs help with this issue. Please let us know the next steps and any information you need.',
        priority: Ticket::PRIORITIES[i % 4], category_id: categories[i % 3].id
      })
      age = (i + 2).hours
      status = Ticket::STATUSES[i % 5]
      ticket.update!(status: status, assignee: i.even? ? agents[i % agents.length] : nil,
        created_at: Time.current - age, updated_at: Time.current - i.minutes,
        first_response_due_at: Time.current + (i.even? ? -90 : 180).minutes,
        resolution_due_at: Time.current + (i % 3 == 0 ? -60 : 300).minutes,
        resolved_at: status.in?(%w[resolved closed]) ? Time.current - 30.minutes : nil,
        closed_at: status == 'closed' ? Time.current - 10.minutes : nil)
      unless status == 'closed'
        staff = org.memberships.find_by!(user: agents.first)
        Tickets::AddComment.call(ticket: ticket, membership: staff, attributes: { body: 'Investigating the account configuration.', visibility: 'internal' })
        if i.odd?
          Tickets::AddComment.call(ticket: ticket, membership: staff, attributes: { body: 'Thanks for reporting this. We are investigating and will update you shortly.', visibility: 'public' })
        end
      end
    end
  end
  dual = User.find_or_create_by!(email: 'dual@demo.example') { |u| u.name = 'Demo Workspace Reviewer'; u.password = password }
  organizations['acme'].memberships.find_or_create_by!(user: dual) { |m| m.role = 'admin' }
  organizations['orbit'].memberships.find_or_create_by!(user: dual) { |m| m.role = 'customer' }
end
puts "Local demo ready: #{Organization.count} organizations, #{Ticket.count} tickets. Credentials documented in README."
