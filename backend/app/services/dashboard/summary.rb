module Dashboard
  class Summary
    def self.call(scope, params)
      if params[:from].present?
        scope = scope.where('created_at >= ?', Date.iso8601(params[:from]).beginning_of_day)
      end
      if params[:to].present?
        scope = scope.where('created_at <= ?', Date.iso8601(params[:to]).end_of_day)
      end
      active = scope.active
      statuses = scope.group(:status).count
      { total: scope.count, open: statuses.fetch('open', 0), in_progress: statuses.fetch('in_progress', 0),
        overdue: active.where('resolution_due_at < :now OR (first_response_at IS NULL AND first_response_due_at < :now)', now: Time.current).count,
        resolved_last_30_days: scope.where(status: %w[resolved closed]).where('resolved_at >= ?', 30.days.ago).count,
        by_priority: scope.group(:priority).count, by_status: statuses,
        recent_tickets: scope.includes(:created_by, :assignee, :category).order(updated_at: :desc).limit(5).map { |ticket| TicketSerializer.call(ticket) } }
    rescue Date::Error
      raise Api::V1::BaseController::BadInput, 'Dates must use YYYY-MM-DD'
    end
  end
end
