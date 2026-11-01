class SlaPolicy < ApplicationRecord
  DEFAULTS = { 'urgent' => [60, 240], 'high' => [240, 480], 'normal' => [480, 1440], 'low' => [1440, 4320] }.freeze
  belongs_to :organization
  validates :priority, inclusion: { in: DEFAULTS.keys }, uniqueness: { scope: :organization_id }
  validates :first_response_minutes, :resolution_minutes, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 525600 }
end
