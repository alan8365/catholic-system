# frozen_string_literal: true

class Event < ApplicationRecord
  validates :name, presence: true
  validates :start_at, presence: true

  validate :name_unique_this_year

  has_many :special_donations

  def donation_count
    SpecialDonation.where(event_id: id).count
  end

  private

  def name_unique_this_year
    this_year = start_at&.beginning_of_year..start_at&.end_of_year
    return unless Event.where(name:, start_at: this_year).where.not(id:).exists?

    errors.add(:name, I18n.t('this_name_of_event_is_already_exists_in_this_year'))
  end
end
