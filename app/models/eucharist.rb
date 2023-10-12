# frozen_string_literal: true

# Baptism model
class Eucharist < ApplicationRecord
  belongs_to :parishioner, class_name: 'Parishioner', foreign_key: 'parishioner_id'

  belongs_to :godfather_instance, class_name: 'Parishioner', foreign_key: 'godfather_id', optional: true
  belongs_to :godmother_instance, class_name: 'Parishioner', foreign_key: 'godmother_id', optional: true
  belongs_to :presbyter_instance, class_name: 'Parishioner', foreign_key: 'presbyter_id', optional: true

  validates :eucharist_at, presence: true
  validates :eucharist_location, presence: true

  validates :presbyter, presence: true
  validates :parishioner_id, presence: true, uniqueness: true

  validate :godfather_xor_godmother

  def serial_number
    date_range = eucharist_at.beginning_of_year..eucharist_at.end_of_year
    this_year_array = Eucharist
                      .where(eucharist_at: date_range)
                      .order('eucharist_at', 'id')
                      .pluck(:id)
    number = this_year_array.find_index(id) + 1
    number = number.to_s.rjust(2, '0')

    "#{eucharist_at.year}#{number}"
  end

  private

  def godfather_xor_godmother
    return if godfather.blank? ^ godmother.blank?

    errors.add(:base, I18n.t('specify_a_godfather_or_a_godmother_not_both'))
  end
end
