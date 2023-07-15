# frozen_string_literal: true

class Event < ApplicationRecord
  validates :name, presence: true
  validates :start_at, presence: true
end
