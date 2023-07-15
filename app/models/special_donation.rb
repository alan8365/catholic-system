# frozen_string_literal: true

class SpecialDonation < ApplicationRecord
  validates :event_id, presence: true
  validates :home_number, presence: true
  validates :donation_at, presence: true
  validates :donation_amount, presence: true

  belongs_to :household, class_name: 'Household', foreign_key: 'home_number'
  belongs_to :event, class_name: 'Event', foreign_key: 'event_id'
end
