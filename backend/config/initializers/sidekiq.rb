redis = { url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/0') }
Sidekiq.configure_client { |config| config.redis = redis }
Sidekiq.configure_server do |config|
  config.redis = redis
  config.on(:startup) do
    require 'sidekiq/cron/job'
    job = Sidekiq::Cron::Job.new(name: 'supportflow-sla-scan', cron: ENV.fetch('SLA_SCAN_CRON', '*/5 * * * *'),
      class: 'SlaScanJob', active_job: true, queue: 'default')
    raise "Invalid SLA schedule: #{job.errors.join(', ')}" unless job.save
  end
end
