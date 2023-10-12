# frozen_string_literal: true

class RegularDonation < ApplicationRecord
  validates :home_number, presence: true
  validates :donation_at, presence: true
  validates :donation_amount, presence: true

  validate :sunday_check
  validate :future_check

  belongs_to :household, class_name: 'Household', foreign_key: 'home_number'

  def sunday_check
    return if donation_at&.sunday?

    errors.add(:donation_at, I18n.t('donation_date_should_be_sunday'))
  end

  def future_check
    today = Date.today
    return false if donation_at.nil?
    return if today > donation_at

    errors.add(:donation_at, format(I18n.t('donation_date_should_be_past'), today, donation_at))
  end
end
