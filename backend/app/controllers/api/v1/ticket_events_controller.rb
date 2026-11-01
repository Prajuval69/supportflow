module Api
  module V1
    class TicketEventsController < BaseController
      def index
        scope = find_ticket.ticket_events.where(organization_id: Current.organization.id)
        scope = scope.where(event_type: TicketEvent::PUBLIC_TYPES) unless Current.membership.staff?
        render json: { data: scope.includes(:actor).order(:created_at, :id).map do |event|
          event.slice(:id, :event_type, :metadata, :created_at).merge(actor: event.actor&.slice(:id, :name))
        end }
      end
    end
  end
end
