class Comment < ApplicationRecord
  belongs_to :organization
  belongs_to :ticket
  belongs_to :author, class_name: 'User'
  validates :body, presence: true, length: { maximum: 10_000 }
  validates :visibility, inclusion: { in: %w[public internal] }
  validate do
    errors.add(:ticket, 'tenant mismatch') if ticket.organization_id != organization_id
    membership = organization.memberships.active.find_by(user_id: author_id)
    errors.add(:author, 'must be an active member') unless membership
    errors.add(:visibility, 'requires staff') if visibility == 'internal' && !membership&.staff?
  end
end
