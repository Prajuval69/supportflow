module Api
  module V1
    class CommentsController < BaseController
      def index
        scope = find_ticket.comments.where(organization_id: Current.organization.id)
        scope = scope.where(visibility: 'public') unless Current.membership.staff?
        render json: { data: scope.includes(:author).order(:created_at, :id).map { |comment| serialize(comment) } }
      end

      def create
        comment = Tickets::AddComment.call(ticket: find_ticket, membership: Current.membership,
          attributes: params.require(:comment).permit(:body, :visibility).to_h)
        render json: { data: serialize(comment) }, status: :created
      end

      private

      def serialize(comment)
        comment.slice(:id, :body, :visibility, :created_at).merge(author: comment.author.slice(:id, :name))
      end
    end
  end
end
