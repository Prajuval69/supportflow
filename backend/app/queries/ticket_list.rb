class TicketList
  SORTS = { 'created_at' => :created_at, 'updated_at' => :updated_at, 'priority' => :priority }.freeze
  def self.call(scope, params)
    %w[status priority category_id assignee_id].each do |key|
      scope = scope.where(key => params[key]) if params[key].present?
    end
    if params[:q].present?
      query = "%#{Ticket.sanitize_sql_like(params[:q].to_s.first(200))}%"
      scope = scope.where('title ILIKE :q OR ticket_number ILIKE :q', q: query)
    end
    sort = SORTS[params.fetch(:sort, 'created_at')]
    direction = params.fetch(:direction, 'desc')
    unless sort && direction.in?(%w[asc desc])
      raise Api::V1::BaseController::BadInput, 'Invalid sort or direction'
    end
    if sort == :priority
      # Fixed SQL, no user strings. Business priority order, rather than alphabetic.
      expression = Arel.sql("CASE priority WHEN 'low' THEN 0 WHEN 'normal' THEN 1 WHEN 'high' THEN 2 WHEN 'urgent' THEN 3 END")
      scope = scope.order(direction == 'asc' ? expression.asc : expression.desc)
    else
      scope = scope.order(sort => direction)
    end
    scope.order(id: :asc).includes(:created_by, :assignee, :category)
  end
end
