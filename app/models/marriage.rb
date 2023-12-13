# frozen_string_literal: true

# Baptism model
class Marriage < ApplicationRecord
  belongs_to :groom_instance, class_name: 'Parishioner', foreign_key: 'groom_id', optional: true
  belongs_to :bride_instance, class_name: 'Parishioner', foreign_key: 'bride_id', optional: true

  belongs_to :presbyter_instance, class_name: 'Parishioner', foreign_key: 'presbyter_id', optional: true

  validates :groom, presence: true
  validates :bride, presence: true

  validates :marriage_at, presence: true
  validates :marriage_location, presence: true

  validate :check_foreign_key_existence

  def serial_number
    date_range = marriage_at.beginning_of_year..marriage_at.end_of_year
    this_year_array = Marriage
                      .where(marriage_at: date_range)
                      .order('marriage_at', 'id')
                      .pluck(:id)
    number = this_year_array.find_index(id) + 1
    number = number.to_s.rjust(2, '0')

    "M#{marriage_at.year}#{number}"
  end

  def check_foreign_key_existence
    if groom_id.present? && !Parishioner.exists?(groom_id)
      errors.add(:base, I18n.t('activerecord.errors.models.sacraments.attributes.groom_id.not_found'))
    end

    if bride_id.present? && !Parishioner.exists?(bride_id)
      errors.add(:base, I18n.t('activerecord.errors.models.sacraments.attributes.bride_id.not_found'))
    end

    true
  end
end
