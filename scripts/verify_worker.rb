abort 'Worker verification is development-only' unless Rails.env.development?
require 'sidekiq/api'
require 'json'
org = Organization.find_by!(slug: 'acme-demo')
actor = org.memberships.active.where(role: 'customer').first!.user
ticket = Tickets::Create.call(organization: org, actor: actor, attributes: {
  title: 'Verified Redis worker escalation', description: 'Integration evidence from a real Sidekiq worker.', priority: 'urgent'
})
ticket.update!(first_response_due_at: 10.minutes.ago, resolution_due_at: 5.minutes.ago)
abort 'Start a real Sidekiq worker before verification' if Sidekiq::ProcessSet.new.size.zero?
SlaScanJob.perform_later
deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30
loop do
  break if ApplicationRecord.uncached { ticket.ticket_events.where(event_type: 'sla_breached').count == 2 }
  abort 'Timed out waiting for real worker breach events' if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
  sleep 0.2
end
baseline = Sidekiq::Stats.new.processed
2.times { %w[first_response resolution].each { |kind| SlaBreachJob.perform_later(org.id, ticket.id, kind) } }
deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30
loop do
  break if Sidekiq::Stats.new.processed >= baseline + 4 && Sidekiq::Queue.new.size.zero?
  abort 'Timed out waiting for retry jobs' if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
  sleep 0.2
end
events = ticket.ticket_events.where(event_type: 'sla_breached').count
notifications = org.notifications.where(ticket: ticket).count
expected = org.memberships.active.where(role: 'admin').count * 2
abort "Deduplication failed: #{events} events / #{notifications} notifications" unless events == 2 && notifications == expected
evidence = { checked_at: Time.current.iso8601, status: 'PASS', adapter: ActiveJob::Base.queue_adapter.class.name,
  ticket_id: ticket.id, ticket_number: ticket.ticket_number, breach_events: events, notifications: notifications,
  duplicate_jobs_enqueued: 4, live_sidekiq_processes: Sidekiq::ProcessSet.new.size,
  scheduled_scan: Sidekiq.redis { |redis| redis.call('EXISTS', 'cron_job:default:supportflow-sla-scan') } == 1 }
path = Rails.root.join('../docs/evidence/worker.json')
FileUtils.mkdir_p(path.dirname)
File.write(path, JSON.pretty_generate(evidence))
puts JSON.pretty_generate(evidence)
