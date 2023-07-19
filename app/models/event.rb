# frozen_string_literal: true

class Event < ApplicationRecord
  validates :name, presence: true
  validates :start_at, presence: true

  has_many :special_donations
end
