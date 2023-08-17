# frozen_string_literal: true

class Event < ApplicationRecord
  validates :name, presence: true
  validates :start_at, presence: true

  has_many :special_donations

  def donation_count
    SpecialDonation.where(event_id: id).count
  end

  def five
    5
  end
end
