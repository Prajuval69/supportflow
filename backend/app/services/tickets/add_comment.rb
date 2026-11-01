module Tickets
  class AddComment
    def self.call(ticket:, membership:, attributes:)
      unless TicketPolicy.new(membership).scope.exists?(id: ticket.id)
        raise ActiveRecord::RecordNotFound
      end
      attrs = attributes.symbolize_keys
      if attrs[:visibility] == 'internal' && !membership.staff?
        raise Api::V1::BaseController::Forbidden, 'Internal notes require staff'
      end
      comment = nil
      ticket.with_lock do
        raise Api::V1::BaseController::Conflict, 'Closed tickets are read-only' if ticket.status == 'closed'
        comment = ticket.comments.create!(organization_id: membership.organization_id, author_id: membership.user_id,
          body: attrs[:body], visibility: attrs.fetch(:visibility, 'public'))
        if comment.visibility == 'public' && membership.staff? && ticket.first_response_at.nil?
          ticket.update!(first_response_at: Time.current)
        end
        ticket.ticket_events.create!(organization_id: ticket.organization_id, actor_id: membership.user_id,
          event_type: comment.visibility == 'internal' ? 'internal_note' : 'public_reply')
      end
      comment
    end
  end
end
