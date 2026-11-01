module Tickets
  class Create
    def self.call(organization:, actor:, attributes:)
      ticket = nil
      organization.with_lock do
        attrs = attributes.symbolize_keys
        category = organization.categories.where(active: true).find(attrs[:category_id]) if attrs[:category_id].present?
        priority = attrs.fetch(:priority, 'normal')
        policy = organization.sla_policies.find_by!(priority: priority)
        organization.increment!(:ticket_sequence)
        ticket = organization.tickets.create!(title: attrs[:title], description: attrs[:description],
          priority: priority, created_by: actor, category: category,
          ticket_number: "#{organization.slug.split('-').first.upcase}-#{organization.ticket_sequence.to_s.rjust(4, '0')}",
          first_response_due_at: Time.current + policy.first_response_minutes.minutes,
          resolution_due_at: Time.current + policy.resolution_minutes.minutes)
        ticket.ticket_events.create!(organization: organization, actor: actor, event_type: 'created')
      end
      ticket
    end
  end
end
