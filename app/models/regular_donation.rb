# frozen_string_literal: true

class RegularDonation < ApplicationRecord
  validates :home_number, presence: true
  validates :donation_at, presence: true
  validates :donation_amount, presence: true

  validate :sunday_check

  belongs_to :household, class_name: 'Household', foreign_key: 'home_number'

  def sunday_check
    return if donation_at&.sunday?

    errors.add(:donation_at, 'Donation date should be sunday.')
  end
end
