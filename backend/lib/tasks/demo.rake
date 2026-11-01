namespace :demo do
  desc 'Make one local Acme ticket overdue and enqueue a real SLA scan (development only)'
  task overdue: :environment do
    abort 'Development only' unless Rails.env.development?
    org = Organization.find_by!(slug: 'acme-demo')
    actor = org.memberships.active.where(role: 'customer').first!.user
    ticket = Tickets::Create.call(organization: org, actor: actor, attributes: {
      title: 'Local SLA worker demonstration', description: 'Created by demo:overdue to demonstrate actual Redis and Sidekiq processing.', priority: 'urgent'
    })
    ticket.update!(first_response_due_at: 10.minutes.ago, resolution_due_at: 5.minutes.ago)
    SlaScanJob.perform_later
    puts "Enqueued scan for #{ticket.ticket_number} (#{ticket.id}); keep Sidekiq running."
  end
end
