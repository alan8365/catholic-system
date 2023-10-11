# frozen_string_literal: true

# Baptism model
class Confirmation < ApplicationRecord
  belongs_to :parishioner, class_name: 'Parishioner', foreign_key: 'parishioner_id'

  belongs_to :godfather_instance, class_name: 'Parishioner', foreign_key: 'godfather_id', optional: true
  belongs_to :godmother_instance, class_name: 'Parishioner', foreign_key: 'godmother_id', optional: true
  belongs_to :presbyter_instance, class_name: 'Parishioner', foreign_key: 'presbyter_id', optional: true

  validates :confirmed_at, presence: true
  validates :confirmed_location, presence: true

  validates :presbyter, presence: true
  validates :parishioner_id, presence: true, uniqueness: true

  validate :godfather_xor_godmother

  def serial_number
    date_range = confirmed_at.beginning_of_year..confirmed_at.end_of_year
    this_year_array = Confirmation
                      .where(confirmed_at: date_range)
                      .order('confirmed_at', 'id')
                      .pluck(:id)
    number = this_year_array.find_index(id) + 1
    number = number.to_s.rjust(2, '0')

    "#{confirmed_at.year}#{number}"
  end

  def godparent
    gender_flag = godfather.present?

    if gender_flag
      godfather
    else
      godmother
    end
  end

  private

  def godfather_xor_godmother
    return if godfather.blank? ^ godmother.blank?

    errors.add(:base, 'Specify a godfather or a godmother, not both')
  end
end
