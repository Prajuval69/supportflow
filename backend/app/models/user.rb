class User < ApplicationRecord
  has_secure_password
  has_many :memberships, dependent: :restrict_with_exception
  has_many :organizations, through: :memberships
  normalizes :email, with: ->(value) { value.strip.downcase }
  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 12, maximum: 72 }, allow_nil: true
end
