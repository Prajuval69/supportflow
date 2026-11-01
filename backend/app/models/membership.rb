class Membership < ApplicationRecord
  ROLES = %w[admin agent customer].freeze
  belongs_to :organization
  belongs_to :user
  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :organization_id }
  scope :active, -> { where(active: true) }
  scope :staff, -> { where(role: %w[admin agent]) }
  def staff? = role.in?(%w[admin agent])
  def admin? = role == 'admin'
end
