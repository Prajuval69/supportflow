require_relative 'boot'
require 'rails'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'active_job/railtie'
require 'rails/test_unit/railtie'
Bundler.require(*Rails.groups)
module Supportflow
  class Application < Rails::Application
    config.load_defaults 7.2
    config.time_zone = 'UTC'
    config.active_job.queue_adapter = :sidekiq
    config.action_controller.default_protect_from_forgery = true
    config.action_controller.forgery_protection_origin_check = true
    config.session_store :cookie_store, key: '_supportflow_session', httponly: true,
      same_site: :lax, secure: Rails.env.production?
    config.filter_parameters += [:password, :password_confirmation, :authenticity_token, :description, :body]
    config.generators.system_tests = nil
    config.secret_key_base = if Rails.env.production?
      ENV.fetch('SECRET_KEY_BASE')
    else
      # Local secret is generated once, ignored, and never committed.
      path = root.join('tmp/local_secret')
      FileUtils.mkdir_p(path.dirname)
      File.write(path, SecureRandom.hex(64)) unless path.exist?
      File.read(path)
    end
  end
end
