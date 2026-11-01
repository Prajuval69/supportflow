class TicketEvent < ApplicationRecord
  PUBLIC_TYPES = %w[created status_changed public_reply].freeze
  belongs_to :organization
  belongs_to :ticket
  belongs_to :actor, class_name: 'User', optional: true
  before_update { throw :abort }
  before_destroy { throw :abort }
end
