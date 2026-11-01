class TicketPolicy
  def initialize(membership)
    @membership = membership
  end
  def scope
    return Ticket.none unless @membership.active?
    base = Ticket.where(organization_id: @membership.organization_id)
    @membership.staff? ? base : base.where(created_by_id: @membership.user_id)
  end
end
