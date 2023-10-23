# frozen_string_literal: true

# Baptism model
class Baptism < ApplicationRecord
  belongs_to :parishioner, class_name: 'Parishioner', foreign_key: 'parishioner_id'

  belongs_to :godfather_instance, class_name: 'Parishioner', foreign_key: 'godfather_id', optional: true
  belongs_to :godmother_instance, class_name: 'Parishioner', foreign_key: 'godmother_id', optional: true
  belongs_to :presbyter_instance, class_name: 'Parishioner', foreign_key: 'presbyter_id', optional: true

  validates :baptized_at, presence: true
  validates :baptized_location, presence: true
  validates :christian_name, presence: true

  validates :presbyter, presence: true
  validates :parishioner_id, presence: true, uniqueness: true

  validate :godfather_xor_godmother

  def godparent
    gender_flag = godfather.present?

    if gender_flag
      godfather
    else
      godmother
    end
  end

  # @return [String (frozen)]
  def serial_number
    date_range = baptized_at.beginning_of_year..baptized_at.end_of_year
    this_year_array = Baptism
                      .where(baptized_at: date_range)
                      .order('baptized_at', 'id')
                      .pluck(:id)
    number = this_year_array.find_index(id) + 1
    number = number.to_s.rjust(2, '0')

    "B#{baptized_at.year}#{number}"
  end

  private

  def godfather_xor_godmother
    return if godfather.blank? ^ godmother.blank?

    errors.add(:base, I18n.t('specify_a_godfather_or_a_godmother_not_both'))
  end
end
