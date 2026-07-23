class Tryon < ApplicationRecord
  belongs_to :user
  has_one_attached :person_photo
  has_many_attached :clothing_photos
  has_many_attached :result_images

  validates :person_photo, presence: true
  validates :clothing_photos, presence: true
end
