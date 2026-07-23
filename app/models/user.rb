class User < ApplicationRecord
  has_secure_password
  has_one_attached :profile_photo
  has_one_attached :base_photo
  has_many :tryons, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: true
end
