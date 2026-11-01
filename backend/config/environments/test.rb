Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = ENV['CI'].present?
  config.consider_all_requests_local = false
  config.action_dispatch.show_exceptions = :none
  config.action_controller.allow_forgery_protection = true
  config.active_job.queue_adapter = :test
end
