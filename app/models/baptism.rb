# frozen_string_literal: true

# Baptism model
class Baptism < ApplicationRecord
  belongs_to :parishioner, class_name: 'Parishioner', foreign_key: 'baptized_person'

  belongs_to :godfather_instance, class_name: 'Parishioner', foreign_key: 'godfather_id', optional: true
  belongs_to :godmother_instance, class_name: 'Parishioner', foreign_key: 'godmother_id', optional: true
  belongs_to :baptist_instance, class_name: 'Parishioner', foreign_key: 'baptist_id', optional: true

  validates :baptized_at, presence: true
  validates :baptized_location, presence: true
  validates :christian_name, presence: true

  validates :baptist, presence: true
  validates :baptized_person, presence: true
  validate :godfather_xor_godmother

  private

  def godfather_xor_godmother
    return if godfather.blank? ^ godmother.blank?

    errors.add(:base, 'Specify a godfather or a godmother, not both')
  end
end
