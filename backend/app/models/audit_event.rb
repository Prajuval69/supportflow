class AuditEvent < ApplicationRecord
  belongs_to :organization
  belongs_to :actor, class_name: 'User'
  before_update { throw :abort }
  before_destroy { throw :abort }
end
