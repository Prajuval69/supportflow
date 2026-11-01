class Organization < ApplicationRecord
  has_many :memberships, dependent: :restrict_with_exception
  has_many :users, through: :memberships
  has_many :tickets, dependent: :restrict_with_exception
  has_many :categories, dependent: :restrict_with_exception
  has_many :sla_policies, dependent: :restrict_with_exception
  has_many :notifications, dependent: :restrict_with_exception
  has_many :audit_events, dependent: :restrict_with_exception
  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
end
