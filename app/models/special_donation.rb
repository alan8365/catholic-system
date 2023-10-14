# frozen_string_literal: true

class SpecialDonation < ApplicationRecord
  validates :event_id, presence: true, uniqueness: { scope: :home_number }
  validates :home_number, presence: true
  validates :donation_at, presence: true
  validates :donation_amount, presence: true

  belongs_to :household, class_name: 'Household', foreign_key: 'home_number'
  belongs_to :event, class_name: 'Event', foreign_key: 'event_id'

  def pair_unique
    sd = SpecialDonation.where(event_id:, home_number:)

    puts sd.as_json
    puts SpecialDonation.all.as_json

    return if sd.empty?

    errors.add(:base,
               format(I18n.t('event_and_home_number_pair_unique'), event_id: event_id.to_s,
                                                                   home_number: home_number.to_s))
  end
end
