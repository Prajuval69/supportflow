module Api
  module V1
    class TicketsController < BaseController
      def index
        rows, meta = paginate(TicketList.call(ticket_scope, params))
        render json: { data: rows.map { |ticket| TicketSerializer.call(ticket) }, meta: meta }
      end

      def show = render(json: { data: TicketSerializer.call(find_ticket) })

      def create
        attrs = params.require(:ticket).permit(:title, :description, :priority, :category_id)
        unless Ticket::PRIORITIES.include?(attrs.fetch(:priority, 'normal'))
          raise BadInput, 'Invalid priority'
        end
        ticket = Tickets::Create.call(organization: Current.organization, actor: Current.user, attributes: attrs.to_h)
        render json: { data: TicketSerializer.call(ticket) }, status: :created
      end

      def update
        ticket = find_ticket
        staff!
        ticket = Tickets::Update.call(ticket: ticket, membership: Current.membership,
          attributes: params.require(:ticket).permit(:status, :priority, :assignee_id, :category_id).to_h)
        render json: { data: TicketSerializer.call(ticket) }
      end
    end
  end
end
