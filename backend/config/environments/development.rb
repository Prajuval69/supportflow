Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.hosts += ['127.0.0.1', 'localhost']
end
