# frozen_string_literal: true

class Parishioner < ApplicationRecord
  # Home number association
  belongs_to :household, class_name: 'Household', foreign_key: 'home_number', optional: true

  # Head of household association
  has_one :head_home_number, class_name: 'Household', foreign_key: 'head_of_household'

  # Self join association
  has_one :spouse_instance, class_name: 'Parishioner', foreign_key: 'spouse_id'
  has_one :mother_instance, class_name: 'Parishioner', foreign_key: 'mother_id'
  has_one :father_instance, class_name: 'Parishioner', foreign_key: 'father_id'

  # Sacrament association
  has_one :baptism, class_name: 'Baptism', foreign_key: 'parishioner_id'
  has_one :confirmation, class_name: 'Confirmation', foreign_key: 'parishioner_id'
  has_one :eucharist, class_name: 'Eucharist', foreign_key: 'parishioner_id'

  # Image
  has_one_attached :picture

  def picture_url
    ActiveStorage::Blob.service.path_for(picture.key)
  end

  validates :name, presence: true
  validates :gender, presence: true
  validates :birth_at, presence: true
end
