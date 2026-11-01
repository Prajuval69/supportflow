module Tickets
  class Update
    def self.call(ticket:, membership:, attributes:)
      raise Api::V1::BaseController::Forbidden, 'Staff access required' unless membership.active? && membership.staff? && membership.organization_id == ticket.organization_id
      ticket.with_lock do
        raise Api::V1::BaseController::Conflict, 'Closed tickets are read-only' if ticket.status == 'closed'
        attrs = attributes.symbolize_keys
        [:assignee_id, :category_id].each do |key|
          attrs[key] = attrs[key].presence if attrs.key?(key)
        end
        if attrs[:status].present? && attrs[:status] != ticket.status
          next_status = attrs[:status]
          unless Ticket::TRANSITIONS.fetch(ticket.status).include?(next_status)
            raise Api::V1::BaseController::Conflict, 'Invalid status transition'
          end
          ticket.ticket_events.create!(organization_id: ticket.organization_id, actor_id: membership.user_id,
            event_type: 'status_changed', metadata: { from: ticket.status, to: next_status })
          attrs[:resolved_at] = next_status.in?(%w[resolved closed]) ? (ticket.resolved_at || Time.current) : nil
          attrs[:closed_at] = next_status == 'closed' ? Time.current : nil
        end
        previous_assignee = ticket.assignee_id
        changes = attrs.slice(:priority, :assignee_id, :category_id).select { |key, value| ticket.public_send(key) != value }
        if attrs[:category_id].present?
          ticket.organization.categories.where(active: true).find(attrs[:category_id])
        end
        ticket.update!(attrs)
        changes.each do |key, value|
          event = ticket.ticket_events.create!(organization_id: ticket.organization_id, actor_id: membership.user_id,
            event_type: "#{key.to_s.delete_suffix('_id')}_changed", metadata: { key => value })
          if key == :assignee_id && value.present? && value != previous_assignee
            TicketAssignedNotificationJob.perform_later(ticket.organization_id, ticket.id, value, event.id)
          end
        end
      end
      ticket
    end
  end
end
