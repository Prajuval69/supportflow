require 'rails_helper'
RSpec.describe 'SLA and assignment processing', type: :job do
  include ApiHelpers
  before do
    @org = create_org('jobs')
    @admin = create_user('jobadmin')
    @agent = create_user('jobagent')
    @customer = create_user('jobcustomer')
    @org.memberships.create!(user: @admin, role: 'admin')
    @org.memberships.create!(user: @agent, role: 'agent')
    @org.memberships.create!(user: @customer, role: 'customer')
    @ticket = Tickets::Create.call(organization: @org, actor: @customer, attributes: { title: 'Overdue', description: 'Work to do', priority: 'urgent' })
    @ticket.update!(assignee: @agent)
  end

  it 'scans overdue candidates and creates one event and notification per kind and recipient on retries' do
    travel 5.hours do
      expect { SlaScanJob.perform_now }.to have_enqueued_job(SlaBreachJob).with(@org.id, @ticket.id, 'first_response')
      expect(enqueued_jobs.count { |job| job[:job] == SlaBreachJob }).to eq(2)
      2.times do
        SlaBreachJob.perform_now(@org.id, @ticket.id, 'first_response')
        SlaBreachJob.perform_now(@org.id, @ticket.id, 'resolution')
      end
      expect(@ticket.ticket_events.where(event_type: 'sla_breached').count).to eq(2)
      expect(Notification.where(ticket: @ticket).count).to eq(4)
      expect(Notification.where(user: @customer)).to be_empty
    end
  end

  it 'rechecks resolved, answered, future deadlines and wrong-tenant arguments' do
    other = create_org('otherjobs')
    travel 5.hours do
      SlaBreachJob.perform_now(other.id, @ticket.id, 'resolution')
      SlaBreachJob.perform_now(@org.id, @ticket.id, 'unknown')
      @ticket.update!(first_response_at: Time.current)
      SlaBreachJob.perform_now(@org.id, @ticket.id, 'first_response')
      @ticket.update!(status: 'resolved', resolved_at: Time.current)
      SlaBreachJob.perform_now(@org.id, @ticket.id, 'resolution')
    end
    @ticket.update!(status: 'open', first_response_at: nil)
    SlaBreachJob.perform_now(@org.id, @ticket.id, 'resolution')
    expect(@ticket.ticket_events.where(event_type: 'sla_breached')).to be_empty
    expect(Notification.count).to eq(0)
  end

  it 'deduplicates assignments and skips stale event, recipient and tenant' do
    event = @ticket.ticket_events.create!(organization: @org, actor: @admin, event_type: 'assignee_changed', metadata: { assignee_id: @agent.id })
    2.times { TicketAssignedNotificationJob.perform_now(@org.id, @ticket.id, @agent.id, event.id) }
    expect(Notification.where(user: @agent).count).to eq(1)
    @ticket.update!(assignee: @admin)
    TicketAssignedNotificationJob.perform_now(@org.id, @ticket.id, @agent.id, event.id)
    @ticket.update!(assignee: @agent)
    newer = @ticket.ticket_events.create!(organization: @org, actor: @admin, event_type: 'assignee_changed', metadata: { assignee_id: @agent.id })
    TicketAssignedNotificationJob.perform_now(@org.id, @ticket.id, @agent.id, event.id)
    TicketAssignedNotificationJob.perform_now(create_org('wrongjobs').id, @ticket.id, @agent.id, newer.id)
    expect(Notification.count).to eq(1)
  end
end
