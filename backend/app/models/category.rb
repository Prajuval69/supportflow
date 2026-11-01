class Category < ApplicationRecord
  belongs_to :organization
  validates :name, presence: true, length: { maximum: 80 }, uniqueness: { scope: :organization_id, case_sensitive: false }
end
