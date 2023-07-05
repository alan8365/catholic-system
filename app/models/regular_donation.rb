# frozen_string_literal: true

class RegularDonation < ApplicationRecord
  validates :home_number, presence: true
  validates :donation_at, presence: true
  validates :donation_amount, presence: true

  belongs_to :household, class_name: 'Household', foreign_key: 'home_number'
end
