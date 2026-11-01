class Notification < ApplicationRecord
  belongs_to :organization
  belongs_to :user
  belongs_to :ticket, optional: true
  validates :kind, :message, :dedupe_key, presence: true
end
