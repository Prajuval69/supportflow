module Api
  module V1
    class NotificationsController < BaseController
      def index
        scope = authorized_notifications
        rows, meta = paginate(scope.order(created_at: :desc, id: :asc))
        render json: { data: rows.map { |n| serialize(n) }, meta: meta, unread_count: scope.where(read_at: nil).count }
      end

      def read
        notification = authorized_notifications.find(params[:id])
        notification.update!(read_at: notification.read_at || Time.current)
        render json: { data: serialize(notification) }
      end

      private

      def authorized_notifications
        scope = Current.organization.notifications.where(user_id: Current.user.id)
        scope = scope.where(ticket_id: ticket_scope.select(:id)).or(scope.where(ticket_id: nil))
        scope = scope.where.not(kind: %w[sla_breach assignment]) unless Current.membership.staff?
        scope
      end

      def serialize(notification)
        notification.slice(:id, :ticket_id, :kind, :message, :read_at, :created_at)
      end
    end
  end
end
