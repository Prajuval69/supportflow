class TicketSerializer
  def self.call(ticket)
    ticket.slice(:id, :ticket_number, :title, :description, :status, :priority, :created_at, :updated_at,
      :first_response_at, :first_response_due_at, :resolution_due_at, :resolved_at, :closed_at).merge(
      created_by: ticket.created_by.slice(:id, :name), assignee: ticket.assignee&.slice(:id, :name),
      category: ticket.category&.slice(:id, :name), overdue: ticket.overdue?)
  end
end
