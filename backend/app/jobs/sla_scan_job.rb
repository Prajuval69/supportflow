class SlaScanJob < ApplicationJob
  queue_as :default
  def perform
    now = Time.current
    Organization.find_each do |organization|
      scope = organization.tickets.active
      scope.where(first_response_at: nil).where('first_response_due_at < ?', now).find_each do |ticket|
        SlaBreachJob.perform_later(organization.id, ticket.id, 'first_response')
      end
      scope.where('resolution_due_at < ?', now).find_each do |ticket|
        SlaBreachJob.perform_later(organization.id, ticket.id, 'resolution')
      end
    end
  end
end
