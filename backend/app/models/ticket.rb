class Ticket < ApplicationRecord
  PRIORITIES = %w[low normal high urgent].freeze
  STATUSES = %w[open in_progress waiting_on_customer resolved closed].freeze
  TRANSITIONS = {
    'open' => %w[in_progress resolved],
    'in_progress' => %w[waiting_on_customer resolved],
    'waiting_on_customer' => %w[in_progress resolved],
    'resolved' => %w[in_progress closed],
    'closed' => []
  }.freeze
  belongs_to :organization
  belongs_to :created_by, class_name: 'User'
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :category, optional: true
  has_many :comments, dependent: :restrict_with_exception
  has_many :ticket_events, dependent: :restrict_with_exception
  validates :title, presence: true, length: { maximum: 200 }
  validates :description, presence: true, length: { maximum: 20_000 }
  validates :priority, inclusion: { in: PRIORITIES }
  validates :status, inclusion: { in: STATUSES }
  validates :ticket_number, :first_response_due_at, :resolution_due_at, presence: true
  validate :tenant_associations
  scope :active, -> { where.not(status: %w[resolved closed]) }

  def overdue?(now = Time.current)
    !status.in?(%w[resolved closed]) &&
      (resolution_due_at < now || (first_response_at.nil? && first_response_due_at < now))
  end

  private

  def tenant_associations
    members = Membership.active.where(organization_id: organization_id)
    errors.add(:created_by, 'must be an active organization member') unless members.exists?(user_id: created_by_id)
    if assignee_id && !members.staff.exists?(user_id: assignee_id)
      errors.add(:assignee, 'must be active staff in this organization')
    end
    errors.add(:category, 'must belong to this organization') if category && category.organization_id != organization_id
  end
end
