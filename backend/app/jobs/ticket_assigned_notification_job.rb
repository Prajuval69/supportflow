class TicketAssignedNotificationJob < ApplicationJob
  queue_as :default
  def perform(organization_id, ticket_id, assignee_id, event_id)
    ticket = Ticket.where(organization_id: organization_id).find_by(id: ticket_id)
    return unless ticket
    ticket.with_lock do
      return unless ticket.assignee_id == assignee_id
      member = Membership.active.staff.find_by(organization_id: organization_id, user_id: assignee_id)
      return unless member
      event = ticket.ticket_events.where(organization_id: organization_id, event_type: 'assignee_changed').order(created_at: :desc, id: :desc).first
      return unless event&.id == event_id && event.metadata['assignee_id'] == assignee_id
      Notification.find_or_create_by!(organization_id: organization_id, user_id: assignee_id, dedupe_key: "assignment:#{event_id}") do |notification|
        notification.ticket = ticket
        notification.kind = 'assignment'
        notification.message = "#{ticket.ticket_number} was assigned to you"
      end
    end
  end
end
