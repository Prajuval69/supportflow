class ApplicationJob < ActiveJob::Base
  retry_on ActiveRecord::Deadlocked, ActiveRecord::ConnectionNotEstablished, wait: :polynomially_longer, attempts: 5
end
