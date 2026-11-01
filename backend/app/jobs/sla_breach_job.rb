class SlaBreachJob < ApplicationJob
  queue_as :default
  def perform(organization_id, ticket_id, kind)
    return unless kind.in?(%w[first_response resolution])
    ticket = Ticket.where(organization_id: organization_id).find_by(id: ticket_id)
    return unless ticket
    ticket.with_lock do
      return if ticket.status.in?(%w[resolved closed])
      breached = if kind == 'first_response'
        ticket.first_response_at.nil? && ticket.first_response_due_at < Time.current
      else
        ticket.resolution_due_at < Time.current
      end
      return unless breached
      key = "sla:#{kind}"
      return if ticket.ticket_events.exists?(organization_id: organization_id, dedupe_key: key)
      ticket.ticket_events.create!(organization_id: organization_id, event_type: 'sla_breached', dedupe_key: key,
        metadata: { kind: kind, due_at: (kind == 'first_response' ? ticket.first_response_due_at : ticket.resolution_due_at).iso8601 })
      recipients = Membership.active.where(organization_id: organization_id, role: 'admin')
      recipients = recipients.or(Membership.active.staff.where(organization_id: organization_id, user_id: ticket.assignee_id)) if ticket.assignee_id
      recipients.find_each do |member|
        Notification.find_or_create_by!(organization_id: organization_id, user_id: member.user_id,
          dedupe_key: "#{ticket.id}:#{key}") do |notification|
          notification.ticket = ticket
          notification.kind = 'sla_breach'
          notification.message = "#{ticket.ticket_number} missed its #{kind.tr('_', ' ')} target"
        end
      end
    end
  end
end
